Envs used to test the extended path issue in this directory.

`conda_pack_081a.yml` will not succeed unless a channel containing the
version of the `conda-pack` distribution present in this directory  is used.
Workaround: create the env, then manually install the `conda-pack` dist
present in this directory.
