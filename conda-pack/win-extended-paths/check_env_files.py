#!/usr/bin/env python3
"""
Check key files in a Conda environment for Windows extended-length path format issues.

This script checks for the presence of extended-length path prefixes (//?/ or \\?\)
in critical conda environment files that could cause issues with PowerShell execution
policies or other path-related problems.
"""

import argparse
import os
import sys
from pathlib import Path
from typing import List, Tuple, Optional


def check_file_for_extended_paths(file_path: Path) -> List[str]:
    """Check a file for Windows extended-length path prefixes.
    
    :param file_path: Path to the file to check
    :return: List of issues found (empty if no issues)
    """
    issues = []
    
    if not file_path.exists():
        return [f"File does not exist: {file_path}"]
        
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        # Check for extended-length path prefixes
        if '//?/' in content:
            issues.append(f"Found //?/ extended-length path prefix in {file_path}")
            
        if '\\\\?\\' in content:
            issues.append(f"Found \\\\?\\ extended-length path prefix in {file_path}")
            
    except Exception as e:
        issues.append(f"Error reading file {file_path}: {e}")
        
    return issues


def get_files_to_check(env_path: Path) -> List[Path]:
    """Get list of files that need to be checked for extended-length paths.
    
    :param env_path: Path to the conda environment root
    :return: List of file paths to check
    """
    files_to_check = [
        env_path / "shell" / "condabin" / "conda-hook.ps1",
        # Add more files here as needed in the future
        # env_path / "another" / "critical" / "file.txt",
    ]
    
    return files_to_check


def check_conda_environment(env_path: str) -> Tuple[bool, List[str]]:
    """Check a conda environment for extended-length path issues.
    
    :param env_path: Path to the conda environment root directory
    :return: Tuple of (success: bool, issues: List[str])
             success is True if no issues found, False otherwise
    """
    env_path_obj = Path(env_path)
    
    if not env_path_obj.exists():
        return False, [f"Environment path does not exist: {env_path}"]
        
    if not env_path_obj.is_dir():
        return False, [f"Environment path is not a directory: {env_path}"]
    
    # Check if it looks like a conda environment
    conda_meta = env_path_obj / "conda-meta"
    if not conda_meta.exists():
        return False, [f"Not a conda environment (no conda-meta directory): {env_path}"]
    
    all_issues = []
    files_to_check = get_files_to_check(env_path_obj)
    
    for file_path in files_to_check:
        issues = check_file_for_extended_paths(file_path)
        all_issues.extend(issues)
    
    return len(all_issues) == 0, all_issues


def main() -> int:
    """Main function to parse arguments and run the check.
    
    :return: Exit code: 0 if no issues found, non-zero if issues found
    """
    parser = argparse.ArgumentParser(
        description="Check conda environment files for Windows extended-length path issues"
    )
    parser.add_argument(
        "env_path",
        help="Full path to the conda environment directory"
    )
    
    args = parser.parse_args()
    
    print(f"Checking conda environment: {args.env_path}")
    
    success, issues = check_conda_environment(args.env_path)
    
    if success:
        print("✓ No extended-length path issues found")
        return 0
    else:
        print("✗ Extended-length path issues found:", file=sys.stderr)
        for issue in issues:
            print(f"  - {issue}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
