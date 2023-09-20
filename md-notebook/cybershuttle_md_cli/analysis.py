import io

import pandas as pd


def load_energies(
    log_file,
    columns={1: "TS", 13: "Potential", 12: "Temperature", 16: "Pressure"},
):
    energies_data = io.StringIO()
    with open(log_file, "r") as f:
        for line in f:
            if line.startswith("ENERGY:"):
                energies_data.write(line)
    energies_data.seek(0)

    energies = pd.read_csv(energies_data, sep=r"\s+", header=None)
    energies.rename(
        columns=columns,
        inplace=True,
    )
    return energies
