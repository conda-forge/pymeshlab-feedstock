from pathlib import Path
import tempfile

import pymeshlab


assert "generate_boolean_union" in pymeshlab.filter_list()

mesh_set = pymeshlab.MeshSet()
mesh_set.create_cube()

mesh = mesh_set.current_mesh()
assert mesh.vertex_number() == 8
assert mesh.face_number() == 12

mesh_set.compute_normal_per_vertex()
mesh_set.apply_coord_laplacian_smoothing(stepsmoothnum=1)

with tempfile.TemporaryDirectory() as tmpdir:
    output_path = Path(tmpdir) / "cube.ply"
    mesh_set.save_current_mesh(str(output_path), save_vertex_normal=True)
    assert output_path.stat().st_size > 100

    reloaded = pymeshlab.MeshSet()
    reloaded.load_new_mesh(str(output_path))
    assert reloaded.current_mesh().vertex_number() == 8
    assert reloaded.current_mesh().face_number() == 12
