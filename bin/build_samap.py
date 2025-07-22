#!/usr/bin/env python3
"""
Author : Ryan Sonderman
Date   : 2025-06-16
Version: 1.1.0
Purpose: Build a SAMAP object from sams and maps
"""

import argparse
import pickle
import os
from log_utils import log
from samap.mapping import SAMAP
from samap.utils import save_samap  # noqa: F401
from typing import NamedTuple
from pathlib import Path


class Args(NamedTuple):
    """ Command-line arguments for the script"""
    
    sams: str           # List of SAM pickle files to load
    maps: Path          # Path to the maps directory
    name: str           # Name of the output pickle
    outdir: Path    # Path to the output directory


# --------------------------------------------------
def get_args() -> Args:
    """
    Parse and return command-line arguments.

    Returns:
        Args: A named tuple containing parsed command-line arguments for sams_dir, sample_sheet, and f_maps.
    """
    parser = argparse.ArgumentParser(
        description='Build a SAMAP object from a directory of SAMs and a sample sheet',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument(
        '--sams',
        required=True,
        type=str,
        help='List of SAM pickle files to load',
    )

    parser.add_argument(
        '-m', '--maps',
        required=True,
        type=Path,
        help='Path to the maps directory'
    )
    
    parser.add_argument(
        '-n', '--name',
        required=False,
        type=str,
        help='Name of the output pickle',
        default='samap.pkl'
    )
    
    parser.add_argument(
        '-o', '--outdir',
        required=False,
        type=Path,
        help='Path to the output directory',
        default=Path('.')
    )

    args = parser.parse_args()
    return Args(args.sams, args.maps, args.name, args.outdir)

# --------------------------------------------------
def load_pkl(file_path: str):
    """
    Load a pickle file.

    Args:
        file_path (str): Path to the pickle file.

    Returns:
        The loaded object from the pickle file.
    """
    with open(file_path, 'rb') as f:
        return pickle.load(f)


# --------------------------------------------------
def main() -> None:
    
    # 1. Parse command-line arguments
    log("Loading arguments", "INFO")
    args   = get_args()
    sams   = args.sams
    maps   = str(args.maps)
    name   = args.name
    outdir = args.outdir
    
    # 2. Build the species dictionary from the SAMs
    log("Building species dictionary from SAMs", "INFO")
    species_dict = dict([(os.path.basename(sam)[:2], load_pkl(sam)) for sam in sams.lstrip('[').rstrip(']').split(', ')]) 

    # 3. Ensure correct structure of the maps directory
    log(f"Ensuring validity of '{maps}'", "INFO")
    if not maps.endswith('/'): # SAMap *will* crash if passed a dir without a '/'
        maps += '/'
        log(f"Provided maps directory does not end with '/', changing to '{maps}'", "WARN")
    if not Path(maps).exists():
        error_message = f"Maps directory '{maps}' does not exist"
        log(error_message, "ERROR")
        raise FileNotFoundError(error_message)
    else:
        log(f"Maps directory found at '{maps}'", "INFO")
        for map_file in Path(maps).rglob('*.txt'):  # Use rglob for recursive search
            log(f"  Found map file '{map_file}", "DEBUG")

    # 4. Create the SAMAP object
    log("Attempting to create SAMAP object", "INFO")
    samap = SAMAP(
        sams=species_dict,
        f_maps=str(maps),
        save_processed=False,
    )
    log("Successfully created SAMAP object with {len(samap.sams)} SAMs", "INFO")

    # Save SAMAP object
    log("Attempting to pickle SAMAP object", "INFO")
    save_samap(samap, os.path.join(outdir, name))
    log(f"Successfully pickled SAMAP object '{name}' to '{outdir}'")

# --------------------------------------------------
if __name__ == '__main__':
    main()
