"""
-------------------------------------------------------------------------------
This script `preprocessed.py` retrieves data from the latest CSV file created
in the 'data/raw/' directory.

1. It applies preprocessing to the data.

2. The results of the preprocessing are saved in a new CSV file
   in the 'data/processed/' directory, with a name formatted as
   'sales_processed_YYYYMMDD_HHMM.csv'.

3. All preprocessing steps are logged in the
   'logs/preprocessed.logs' file to ensure detailed tracking of the process.

Any errors or anomalies are also logged to ensure traceability.
-------------------------------------------------------------------------------
"""
import sys
import logging
import argparse
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field
import pandas as pd


@dataclass
class Config:
    """
    All path configurations for the script
    """
    root: Path = \
        field(default_factory=lambda: Path(__file__).resolve().parents[1])

    @property
    def raw_dir(self) -> Path:
        return self.root / "data" / "raw"

    @property
    def proc_dir(self) -> Path:
        return self.root / "data" / "processed"

    @property
    def log_dir(self) -> Path:
        return self.root / "logs"

    @property
    def log_file(self) -> Path:
        return self.log_dir / "preprocessed.logs"


def _setup_logging(config: Config) -> None:
    """
    Log the info into the directory
    """
    config.log_dir.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        filename=str(config.log_file),
        level=logging.INFO,
        format="[%(asctime)s] | %(levelname)s | %(message)s",
    )


def _locate_latest_csv_file(config: Config,
                            explicit_path: Path | None = None) -> Path:
    """
    Find the last CSV created/modified in data/raw/
    (or the explicit path if provided)..
    """
    if explicit_path:
        p = explicit_path if \
            explicit_path.is_absolute() else config.root / explicit_path
        if not p.exists():
            raise FileNotFoundError(f"Explicit file not found: {p}")
        return p

    config.raw_dir.mkdir(parents=True, exist_ok=True)
    candidates = list(config.raw_dir.glob("*.csv"))
    if not candidates:
        raise FileNotFoundError(f"No raw CSV files found in: {config.raw_dir}")

    latest = max(candidates, key=lambda p: p.stat().st_mtime)

    return latest


def _process_sales_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """
    Converrt sales data into a  matrix.

    Input: ['timestamp', 'model', 'sales']
    Steps:
      - Validates expected columns.
      - Cleans data: converts 'sales' to numeric,
        handles NaN/negatives,
        and normalizes 'model' names.
      - Pivots data from long to wide (models become columns).
      - Aggregates duplicate entries via sum.
      - Ensures the 'timestamp' is retained as a column (not
        just an index).
      - Forces all sales values to non-negative integers (int64).

    Output: ['timestamp', 'model_a', 'model_b', ...]
    """
    expected = {"timestamp", "model", "sales"}
    missing = expected - set(df.columns)
    if missing:
        raise ValueError(
            f"Missing columns in the raw CSV file: {sorted(missing)}")

    sales = pd.to_numeric(df["sales"], errors="coerce").fillna(0).clip(lower=0)

    models = df["model"].astype(str).str.strip().str.lower()

    timestamps = pd.to_datetime(df["timestamp"], errors="coerce")

    clean_df = pd.DataFrame({
        "timestamp": timestamps,
        "model": models,
        "sales": sales,
        }).dropna(subset=["timestamp", "model"])

    wide = clean_df.pivot_table(
        index="timestamp",
        columns="model",
        values="sales",
        aggfunc="sum",
        fill_value=0
    )

    if wide.empty:
        return pd.DataFrame()

    wide = wide.clip(lower=0).round(0).astype("int64")

    wide = wide.reset_index()

    return wide


def _write_processed_csv(config: Config, df: pd.DataFrame,
                         output_path: Path | None = None) -> Path:
    """
    Saves the processed DataFrame to a CSV file.
    """
    config.proc_dir.mkdir(parents=True, exist_ok=True)
    if output_path is None:
        stamp = datetime.now().strftime("%Y%m%d_%H%M")
        output_path = config.proc_dir / f"sales_processed_{stamp}.csv"
    df.to_csv(output_path, index=False)
    return output_path


def main() -> int:
    """
    Main entry point for the preprocessing script.

    Orchestrates the ETL (Extract, Transform, Load) pipeline:
        1. Parses arguments.
        2. Finds the input file.
        3. Cleans and pivots the data.
        4. Saves the result.

    :return: 0 for success, 1 for failure.
    :rtype: int
    """
    parser = argparse.ArgumentParser(
        description=(
            "GPU sales preprocessing: long (timestamp, model, sales)"
            " -> wide (models)."))

    parser.add_argument("--input", type=str, default=None,
                        help="Explicit entry path (optional).")
    parser.add_argument("--output", type=str, default=None,
                        help="Explicit exit path (optional).")
    args = parser.parse_args()

    config = Config()

    _setup_logging(config)

    logging.info("*** Start of preprocessing ***")
    try:
        input_csv = \
            _locate_latest_csv_file(
                config, Path(args.input) if args.input else None)
        logging.info("Loading the raw file : %s", input_csv)
        df = pd.read_csv(input_csv)
        logging.info("FRaw file loaded with %d rows and %d columns",
                     df.shape[0],
                     df.shape[1])

        df_clean = _process_sales_dataframe(df)
        logging.info("After pivoting & cleaning: %d rows and %d columns",
                     df_clean.shape[0],
                     df_clean.shape[1])

        has_timestamp = "timestamp" in df_clean.columns
        status_ts = "OK (present)" if has_timestamp else "NOT OK (missing)"
        logging.info("Verification of 'timestamp' column: %s", status_ts)

        non_timestamp_cols = [
            col for col in df_clean.columns if col != "timestamp"]

        all_int = all(
            pd.api.types.is_integer_dtype(df_clean[col].dtype)
            for col in non_timestamp_cols
        )

        status_int = "OK (all columns are integers)" if all_int else "NOT OK"
        logging.info("Integer type checking: %s", status_int)

        out_path = Path(args.output) if args.output else None
        out_csv = _write_processed_csv(config, df_clean, out_path)
        logging.info("Preprocessed file saved : %s", out_csv)
        logging.info("*** End of preprocessing ***\n")

        return 0

    except Exception as e:
        logging.info("ERROR during preprocessing : %s", e)
        logging.info("*** End of preprocessing (with errors) ***")
        print(f"[preprocessed.py] Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
