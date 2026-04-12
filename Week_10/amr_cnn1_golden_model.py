import numpy as np


def load_rtl_output(filename: str = "rtl_out.txt") -> np.ndarray:
    """
    Load RTL pooled output dump.
    Expected format per line:
        channel row col value
    Example:
        0 0 0 16
        0 0 1 18
    """
    data = np.loadtxt(filename, dtype=np.int32)

    if data.ndim == 1:
        data = data.reshape(1, 4)

    if data.shape[1] != 4:
        raise ValueError(f"Expected 4 columns in {filename}, got shape {data.shape}")

    return data


def reconstruct_feature_map(data: np.ndarray,
                            num_channels: int = 4,
                            rows: int = 3,
                            cols: int = 3) -> np.ndarray:
    """
    Reconstruct [channel][row][col] feature map from RTL dump.
    """
    fmap = np.zeros((num_channels, rows, cols), dtype=np.int16)

    for idx, (ch, row, col, val) in enumerate(data):
        if not (0 <= ch < num_channels):
            raise ValueError(f"Invalid channel at line {idx}: {ch}")
        if not (0 <= row < rows):
            raise ValueError(f"Invalid row at line {idx}: {row}")
        if not (0 <= col < cols):
            raise ValueError(f"Invalid col at line {idx}: {col}")

        fmap[ch, row, col] = np.int16(val)

    return fmap


def print_feature_map(fmap: np.ndarray) -> None:
    """
    Pretty-print reconstructed feature maps.
    """
    num_channels = fmap.shape[0]

    print("\nReconstructed Feature Maps:")
    for ch in range(num_channels):
        print(f"\nChannel {ch}:")
        print(fmap[ch])


def dump_summary(data: np.ndarray) -> None:
    """
    Print quick summary of the RTL dump.
    """
    ch = data[:, 0]
    row = data[:, 1]
    col = data[:, 2]
    val = data[:, 3]

    print("==============================================")
    print("RTL Output Summary")
    print("==============================================")
    print(f"Total outputs : {len(val)}")
    print(f"Channels      : {sorted(np.unique(ch).tolist())}")
    print(f"Rows          : {sorted(np.unique(row).tolist())}")
    print(f"Cols          : {sorted(np.unique(col).tolist())}")
    print(f"Value min/max : {val.min()} / {val.max()}")

    print("\nFirst 10 entries:")
    for i in range(min(10, len(val))):
        print(f"idx={i:2d}  ch={ch[i]} row={row[i]} col={col[i]} val={val[i]}")


def main() -> None:
    rtl_data = load_rtl_output("rtl_out.txt")
    dump_summary(rtl_data)

    if len(rtl_data) != 36:
        print(f"\nWARNING: Expected 36 pooled outputs, got {len(rtl_data)}")

    fmap = reconstruct_feature_map(rtl_data, num_channels=4, rows=3, cols=3)
    print_feature_map(fmap)


if __name__ == "__main__":
    main()
