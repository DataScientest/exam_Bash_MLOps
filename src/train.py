"""
------------------------------------------------------------
This script runs the training of an XGBoost model to predict
graphics card sales from the preprocessed data.

1. It starts by searching for the latest preprocessed CSV
   file in the 'data/processed/' directory.
2. If a standard model (model.pkl) does not exist, it loads
   the data, splits it into training and test sets, trains a
   model on this data, evaluates it, and then saves it as
   'model/model.pkl'.
3. If a standard model already exists, it trains a new model
   on the latest data, evaluates it, and saves the model in
   the 'model/' folder in the format:
   model_YYYYMMDD_HHMM.pkl.
4. Performance metrics (RMSE, MAE, R²) are displayed and
   saved in the log file.
5. Any errors are handled and reported in the logs.

The models are saved in the 'model/' folder with the name
'model.pkl' for the standard model and with a timestamp for
later versions.
The model metrics are recorded in the script’s log files.
------------------------------------------------------------
"""

import sys
import logging
import argparse
from typing import Any
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field

import numpy as np
import pandas as pd
from pydantic import BaseModel

import joblib
from xgboost import XGBRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score


class ModelParameters(BaseModel):
    """Constant parameters foe training"""
    n_estimators: int = 300
    max_depth: int = 6
    learning_rate: float = 0.05
    subsample: float = 0.9
    colsample_bytree: float = 0.9
    objective: str = "reg:squarederror"
    random_state: int = 42
    n_jobs: int = 0


@dataclass
class Config:
    """
    All path configurations for the script
    """
    root: Path = field(
        default_factory=lambda: Path(__file__).resolve().parents[1])

    @property
    def data_processed(self) -> Path:
        return self.root / "data" / "processed"

    @property
    def model_dir(self) -> Path:
        return self.root / "model"

    @property
    def logs_dir(self) -> Path:
        return self.root / "logs"

    @property
    def train_log(self) -> Path:
        return self.logs_dir / "train.logs"


def _setup_logging(config: Config) -> None:
    """
    Log the info into the directory
    """
    config.logs_dir.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] | %(levelname)s | %(message)s",
        handlers=[
            logging.FileHandler(str(config.train_log)),
            logging.StreamHandler(sys.stdout)],
    )


def _find_latest_processed_csv(processed_dir: Path) -> Path:
    candidates = list(processed_dir.glob("sales_processed_*.csv"))

    if not candidates:
        raise FileNotFoundError(
            f"No CSv files found in: {processed_dir}")

    latest = max(candidates, key=lambda p: p.stat().st_mtime)
    return latest


def _infer_x_y(df: pd.DataFrame, mode: str = 'first'
               ) -> tuple[pd.DataFrame, pd.Series]:
    """
    Infers Feature Matrix (X) and Target Vector (y) from the
    DataFrame.

    Modes:
      'first': y = firt numeric column (model);
      x = other numeric columns.
      'all': y = sum of all numeric c olumns (total sale);
      x = numeric columns.
    """
    df = df.copy()
    if 'timestamp' in df.columns:
        df['timestamp'] = pd.to_datetime(df['timestamp']).astype('int64')

    df_num = df.select_dtypes(include=[np.number])

    if mode == 'first':
        target_col = df_num.columns[0]
        y = df_num[target_col]
        x = df_num.drop(columns=[target_col])
        return x, y

    y = df_num.sum(axis=1)
    x = df_num.astype(float)

    return x, y


def _initialize_model(params: ModelParameters) -> XGBRegressor:
    # parameters for the modek
    return XGBRegressor(**params.model_dump())


def _split_train_eval(x: pd.DataFrame, y: pd.Series
                      ) -> tuple[XGBRegressor, dict]:
    """
    Splits data, trains the model, and evaluates performance.
    """
    x_train, x_test, y_train, y_test = train_test_split(
        x, y, test_size=0.2, random_state=42
    )
    parameters = ModelParameters()

    model = _initialize_model(parameters)
    model.fit(x_train, y_train)  # type: ignore

    y_pred = model.predict(x_test)  # type: ignore

    rmse = float(np.sqrt(mean_squared_error(y_test, y_pred)))
    mae = float(mean_absolute_error(y_test, y_pred))
    r2 = float(r2_score(y_test, y_pred))
    metrics = {"rmse": rmse, "mae": mae, "r2": r2}

    return model, metrics


def _save_model(config: Config, model: Any, standard_path: Path) -> Path:
    config.model_dir.mkdir(parents=True, exist_ok=True)
    if not standard_path.exists():
        joblib.dump(model, standard_path)
        logging.info("Model saved as standard version: %s", standard_path)
        return standard_path

    stamp = datetime.now().strftime("%Y%m%d_%H%M")
    dated_path = config.model_dir / f"model_{stamp}.pkl"
    joblib.dump(model, dated_path)
    logging.info("Model saved with timestamped version: %s", dated_path)

    return dated_path


def main(argv: list[str] | None = None) -> int:
    """
    Main entry point for the training script.

    :return: 0 for success, 1 for error, 2 for file not found.
    """
    parser = argparse.ArgumentParser(
        description="Train a GPU sales prediction model on preprocessed data."
    )
    parser.add_argument(
        "--processed-dir",
        type=str,
        default=None,
        help="Directory with preprocessed CSVs (default: data/processed).",
    )
    args = parser.parse_args(argv)

    config = Config()
    _setup_logging(config)
    target_dir = config.data_processed
    if args.processed_dir:
        target_dir = Path(args.processed_dir)

    logging.info("*** Start of model training ***")
    try:
        latest_csv = _find_latest_processed_csv(target_dir)
        logging.info("Latest processed CSV: %s", latest_csv)

        df = pd.read_csv(latest_csv)
        logging.info("File loded: %s | shape=%s", latest_csv.name, df.shape)

        x, y = _infer_x_y(df)
        logging.info("Training data size: X=%s, y=%s", x.shape, y.shape)

        model, metrics = _split_train_eval(x, y)
        msg: str = (f"Metrics — RMSE: {metrics['rmse']:.4f} | "
                    f"MAE: {metrics['mae']:.4f} | R²: {metrics['r2']:.4f}")
        logging.info(msg)

        standard_model_path = config.model_dir / "model.pkl"
        saved_path = _save_model(config, model, standard_model_path)
        logging.info("Model saved: %s", saved_path)

        logging.info("*** End of model training ***")
        return 0

    except FileNotFoundError as err:
        logging.error(str(err))
        print(f"File error: {err}", file=sys.stderr)
        return 2
    except Exception as err:
        logging.exception("Error during model training")
        print(f"Training error: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
