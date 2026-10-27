import json
import os
from pathlib import Path
import importlib.util
import sys
import traceback

result_path = Path(os.environ['OF_AUTORESULT'])
try:
    # Ubuntu's pvpython can omit dist-packages despite python3-paraview being installed.
    if importlib.util.find_spec('paraview') is None and Path('/usr/lib/python3/dist-packages/paraview/__init__.py').is_file():
        sys.path.append('/usr/lib/python3/dist-packages')
    from paraview.simple import (OpenFOAMReader, GetAnimationScene, GetActiveViewOrCreate,
                                Show, ColorBy, GetColorTransferFunction, GetScalarBar,
                                Render, SaveScreenshot)
    config = json.loads(Path(os.environ['OF_AUTOCONFIG']).read_text())
    reader = OpenFOAMReader(registrationName='pitzDailySteady', FileName=config['case'] + '/benchmark.foam')
    reader.MeshRegions = ['internalMesh']
    reader.CellArrays = ['U', 'p', 'k', 'epsilon', 'nut']
    reader.UpdatePipelineInformation()
    final = max(reader.TimestepValues)
    if final <= 0:
        raise RuntimeError('No solved time steps')
    scene = GetAnimationScene()
    scene.UpdateAnimationUsingDataTimeSteps()
    scene.AnimationTime = final
    view = GetActiveViewOrCreate('RenderView')
    view.ViewTime = final
    reader.UpdatePipeline(final)
    info = reader.GetDataInformation()
    if info.GetNumberOfCells() == 0 or 'U' not in reader.CellData.keys():
        raise RuntimeError('Empty data or missing U')
    display = Show(reader, view)
    display.Representation = 'Surface'
    ColorBy(display, ('CELLS', 'U', 'Magnitude'))
    display.RescaleTransferFunctionToDataRange(True, False)
    display.SetScalarBarVisibility(view, True)
    bar = GetScalarBar(GetColorTransferFunction('U'), view)
    bar.Title = 'U'
    bar.ComponentTitle = 'Magnitude'
    view.CameraPosition = [0.15, 0, 1]
    view.CameraFocalPoint = [0.15, 0, 0]
    view.CameraViewUp = [0, 1, 0]
    view.CameraParallelProjection = 1
    view.ResetCamera()
    Render()
    SaveScreenshot(str(result_path.with_suffix('.png')), view, ImageResolution=[1600, 700])
    result = dict(status='success', time=final, cells=info.GetNumberOfCells(), color='U Magnitude', scalar_bar=bool(bar.Visibility), gui_visual_acceptance='required', velocity_range=list(reader.CellData['U'].GetRange(-1)))
except Exception:
    result = dict(status='failed', error=traceback.format_exc())
# Publish atomically, so the launcher never reads partial JSON.
temp = result_path.with_suffix('.tmp')
temp.write_text(json.dumps(result, indent=2))
temp.replace(result_path)
