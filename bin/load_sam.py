#!/usr/bin/env python3
"""
Author : Ryan Sonderman
Date   : 2025-06-16
Version: 1.2.0
Purpose: Load SAM object from an h5ad file and pickle it
"""

import argparse
from typing import NamedTuple
from pathlib import Path
from samalg import SAM
from log_utils import log
import pickle


class Args(NamedTuple):
    """Command-line arguments for the script"""

    h5ad: Path  # Path to the h5ad file to load
    id2: str  # 2-char ID to associate with the h5ad file
    output: Path # Path to the output directory


# --------------------------------------------------
def get_args() -> Args:
    """
    Parse command-line arguments.

    Returns:
        Args: NamedTuple containing parsed command-line arguments
    """

    parser = argparse.ArgumentParser(
        description="Load SAM object from an h5ad file",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    
    parser.add_argument(
        "--h5ad",
        metavar="FILE",
        type=Path,
        required=True,
        help="Path to the h5ad file to load",
    )
    
    parser.add_argument(
        "--id2",
        metavar="ID",
        type=str,
        required=True,
        help="2-char ID to associate with the h5ad file",
    )
    
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("."),
        help="Directory to save the SAM pickle outputs",
    )

    args = parser.parse_args()

    return Args(args.h5ad, args.id2, args.output)


# --------------------------------------------------
def main() -> None:
    """Load a SAM object from an h5ad file and pickle it""" """build_samap.py
    Main function to load a SAM object from an h5ad file and pickle it.
    This function:
    1. Gets command-line arguments.
    2. Loads the h5ad file into a SAM object.
    3. Pickles the SAM object into the specified output directory.
    """
    
    args = get_args()
    log(f"Loaded h5ad file from {args.h5ad}", level="INFO")
    log(f"Using ID2 {args.id2} for the SAM object", level="INFO")
    
    log("Creating empty SAM object", level="INFO")
    sam = SAM()
    log(f"Loading data from {args.h5ad}", level="INFO")
    sam.load_data(str(args.h5ad))
    log(f"Data loaded successfully for ID2 '{args.id2}'", level="INFO")

    log("Ensuring output directory exists", level="INFO")
    args.output.mkdir(parents=True, exist_ok=True)
    out_path = args.output / f"{args.id2}_sam.pkl"
    log(f"Pickling {args.id2} to {out_path}", level="INFO")
    with open(out_path, "wb") as f:
        pickle.dump(sam, f)
    log(f"Pickling complete for ID2 '{args.id2}'", level="INFO")


# --------------------------------------------------
if __name__ == "__main__":
    main()
