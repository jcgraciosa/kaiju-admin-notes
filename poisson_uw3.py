import underworld3 as uw

res = 128
width = 1
height = 1

qdeg = 3
Tdeg = 2

xmin, xmax = 0, width
ymin, ymax = 0, height

mesh = uw.meshing.UnstructuredSimplexBox(minCoords=(xmin,ymin),
                                        maxCoords=(xmax,ymax),
                                        cellSize= 1. / res, regular=False,
                                        qdegree=qdeg, refinement=0
                                        )

T_soln = uw.discretisation.MeshVariable("T", mesh, 1, degree = Tdeg)

poisson = uw.systems.Poisson(
                                mesh    = mesh,
                                u_Field = T_soln,
                                verbose = False,
                                degree  = 2,
                            )

poisson.constitutive_model = uw.constitutive_models.DiffusionModel
poisson.constitutive_model.Parameters.diffusivity = 0.5

poisson.add_dirichlet_bc((0.0), "Left")
poisson.add_dirichlet_bc((0.0), "Right")
poisson.add_dirichlet_bc((1.0), "Top")
poisson.add_dirichlet_bc((0.0), "Bottom")

poisson.solve()

with mesh.access():
    print(T_soln.data[:].max())

outdir = "/home/juan/mpi-study/out"

mesh.write_timestep(
                    "poisson_out",
                    meshUpdates = True,
                    meshVars = [T_soln],
                    outputPath = outdir,
                    index = 0,
                )
