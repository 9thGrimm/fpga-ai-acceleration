import numpy as np
from pathlib import Path
from collections import defaultdict


# ------------------------------------------------------------
# Generic file loaders
# ------------------------------------------------------------
def load_4col_file(filename: str) -> np.ndarray:
    path = Path(filename)

    if not path.exists():
        print(f"[WARN] File not found: {filename}")
        return np.empty((0, 4), dtype=np.int32)

    try:
        data = np.loadtxt(path, dtype=np.int32)
    except Exception:
        print(f"[WARN] Could not read {filename} or file is empty.")
        return np.empty((0, 4), dtype=np.int32)

    if np.size(data) == 0:
        print(f"[WARN] {filename} is empty.")
        return np.empty((0, 4), dtype=np.int32)

    if data.ndim == 1:
        if data.shape[0] != 4:
            raise ValueError(f"Expected 4 columns in {filename}, got shape {data.shape}")
        data = data.reshape(1, 4)

    if data.shape[1] != 4:
        raise ValueError(f"Expected 4 columns in {filename}, got shape {data.shape}")

    return data


def load_rtl_output(filename: str = "rtl_out.txt") -> np.ndarray:
    return load_4col_file(filename)


def load_conv_dump(filename: str = "rtl_conv_out.txt") -> np.ndarray:
    return load_4col_file(filename)


def load_conv_raw_dump(filename: str = "rtl_conv_raw.txt") -> np.ndarray:
    return load_4col_file(filename)


def load_window_dump(filename: str = "rtl_windows.txt") -> np.ndarray:
    path = Path(filename)

    if not path.exists():
        print(f"[WARN] File not found: {filename}")
        return np.empty((0, 20), dtype=np.int32)

    try:
        data = np.loadtxt(path, dtype=np.int32)
    except Exception:
        print(f"[WARN] Could not read {filename} or file is empty.")
        return np.empty((0, 20), dtype=np.int32)

    if np.size(data) == 0:
        print(f"[WARN] {filename} is empty.")
        return np.empty((0, 20), dtype=np.int32)

    if data.ndim == 1:
        if data.shape[0] != 20:
            raise ValueError(f"Expected 20 columns in {filename}, got shape {data.shape}")
        data = data.reshape(1, 20)

    if data.shape[1] != 20:
        raise ValueError(f"Expected 20 columns in {filename}, got shape {data.shape}")

    return data


# ------------------------------------------------------------
# Reconstruction helpers
# ------------------------------------------------------------
def reconstruct_pool_fmap(
    data: np.ndarray,
    num_channels: int = 4,
    rows: int = 3,
    cols: int = 3,
) -> np.ndarray:
    fmap = np.zeros((num_channels, rows, cols), dtype=np.int16)

    if data.shape[0] == 0:
        return fmap

    for idx, (ch, row, col, val) in enumerate(data):
        if not (0 <= ch < num_channels):
            raise ValueError(f"Invalid channel at line {idx}: {ch}")
        if not (0 <= row < rows):
            raise ValueError(f"Invalid row at line {idx}: {row}")
        if not (0 <= col < cols):
            raise ValueError(f"Invalid col at line {idx}: {col}")

        fmap[ch, row, col] = np.int16(val)

    return fmap


def reconstruct_stage_fmap(
    data: np.ndarray,
    num_channels: int = 4,
    rows: int = 6,
    cols: int = 6,
) -> np.ndarray:
    """
    Reconstruct dense 6x6 conv feature map from RTL tuples:
      ch row_idx col_idx val

    Assumes row_idx/col_idx are true image-space bottom-right coordinates
    of the 3x3 valid window, so:
      row_idx 2..7 -> conv row 0..5
      col_idx 2..7 -> conv col 0..5
    """
    fmap = np.full((num_channels, rows, cols), fill_value=np.nan, dtype=np.float64)

    if data.shape[0] == 0:
        return fmap

    for idx, (ch, row_idx, col_idx, val) in enumerate(data):
        r = row_idx - 2
        c = col_idx - 2

        if not (0 <= ch < num_channels):
            raise ValueError(f"Invalid channel at line {idx}: {ch}")

        if not (0 <= r < rows):
            continue
        if not (0 <= c < cols):
            continue

        fmap[ch, r, c] = val

    return fmap


# ------------------------------------------------------------
# TB input recreation
# ------------------------------------------------------------
def build_input_images() -> tuple[np.ndarray, np.ndarray]:
    img_I = np.arange(64, dtype=np.int32).reshape(8, 8)
    img_Q = np.arange(64, 128, dtype=np.int32).reshape(8, 8)
    return img_I, img_Q


# ------------------------------------------------------------
# Weights copied from conv1_engine_iq RTL
# ------------------------------------------------------------
def get_weights() -> np.ndarray:
    w = np.zeros((4, 2, 3, 3), dtype=np.int32)

    w[0, 0] = np.array([[1, 0, -1], [2, 0, -2], [1, 0, -1]], dtype=np.int32)
    w[0, 1] = np.array([[1, 1, 1], [0, 0, 0], [-1, -1, -1]], dtype=np.int32)

    w[1, 0] = np.array([[0, 1, 0], [1, -4, 1], [0, 1, 0]], dtype=np.int32)
    w[1, 1] = np.array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]], dtype=np.int32)

    w[2, 0] = np.array([[1, 1, 0], [1, 0, -1], [0, -1, -1]], dtype=np.int32)
    w[2, 1] = np.array([[0, 0, 1], [1, 0, 1], [-1, 0, 0]], dtype=np.int32)

    w[3, 0] = np.array([[1, -1, 1], [-1, 1, -1], [1, -1, 1]], dtype=np.int32)
    w[3, 1] = np.array([[1, 0, 1], [0, -4, 0], [1, 0, 1]], dtype=np.int32)

    return w


# ------------------------------------------------------------
# Golden model stages
# ------------------------------------------------------------
def conv2d_iq(img_I: np.ndarray, img_Q: np.ndarray, weights: np.ndarray) -> np.ndarray:
    out = np.zeros((4, 6, 6), dtype=np.int32)

    for ch in range(4):
        wI = weights[ch, 0]
        wQ = weights[ch, 1]

        for r in range(6):
            for c in range(6):
                patch_I = img_I[r:r+3, c:c+3]
                patch_Q = img_Q[r:r+3, c:c+3]
                out[ch, r, c] = np.sum(patch_I * wI) + np.sum(patch_Q * wQ)

    return out


def relu(x: np.ndarray) -> np.ndarray:
    return np.maximum(x, 0).astype(np.int32)


def quantize_int16(x: np.ndarray) -> np.ndarray:
    return np.clip(x, -32768, 32767).astype(np.int16)


def maxpool2x2_stride2_dense(x: np.ndarray) -> np.ndarray:
    out = np.zeros((4, 3, 3), dtype=np.int16)

    for ch in range(4):
        for r in range(3):
            for c in range(3):
                patch = x[ch, 2 * r:2 * r + 2, 2 * c:2 * c + 2]
                out[ch, r, c] = np.max(patch)

    return out


# ------------------------------------------------------------
# Channel remap helpers
# ------------------------------------------------------------
def remap_python_channels_to_rtl(python_fmap: np.ndarray) -> np.ndarray:
    """
    Observed RTL channel order:
      RTL ch0 <- Python ch3
      RTL ch1 <- Python ch0
      RTL ch2 <- Python ch1
      RTL ch3 <- Python ch2
    """
    rtl_fmap = np.zeros_like(python_fmap)
    rtl_fmap[0] = python_fmap[3]
    rtl_fmap[1] = python_fmap[0]
    rtl_fmap[2] = python_fmap[1]
    rtl_fmap[3] = python_fmap[2]
    return rtl_fmap


# ------------------------------------------------------------
# Pretty-print helpers
# ------------------------------------------------------------
def print_fmap(title: str, fmap: np.ndarray) -> None:
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)
    for ch in range(fmap.shape[0]):
        print(f"\nChannel {ch}:")
        print(fmap[ch])


def print_sparse_fmap(title: str, fmap: np.ndarray) -> None:
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)
    for ch in range(fmap.shape[0]):
        print(f"\nChannel {ch}:")
        arr = np.empty_like(fmap[ch], dtype=object)
        for r in range(fmap.shape[1]):
            for c in range(fmap.shape[2]):
                arr[r, c] = "." if np.isnan(fmap[ch, r, c]) else int(fmap[ch, r, c])
        print(arr)


def compare_dense_maps(name: str, rtl_map: np.ndarray, py_map: np.ndarray) -> None:
    print_fmap(f"RTL {name}", rtl_map)
    print_fmap(f"Python {name}", py_map)

    ok = np.array_equal(rtl_map.astype(np.int32), py_map.astype(np.int32))

    print("\n" + "=" * 80)
    print(f"{name.upper()} COMPARISON")
    print("=" * 80)

    if ok:
        print("PASS")
    else:
        print("FAIL")
        diff = rtl_map.astype(np.int32) - py_map.astype(np.int32)
        print_fmap(f"Difference (RTL - Python) for {name}", diff)


def compare_sparse_maps(name: str, rtl_map: np.ndarray, py_map: np.ndarray) -> None:
    print_sparse_fmap(f"RTL {name}", rtl_map)
    print_fmap(f"Python {name}", py_map)

    mask = ~np.isnan(rtl_map)
    rtl_int = np.where(mask, rtl_map, 0).astype(np.int32)
    py_int = py_map.astype(np.int32)

    ok = np.array_equal(rtl_int[mask], py_int[mask])

    print("\n" + "=" * 80)
    print(f"{name.upper()} COMPARISON")
    print("=" * 80)
    print(f"Compared populated entries: {int(np.count_nonzero(mask))}/{int(mask.size)}")

    if ok:
        print("PASS")
    else:
        print("FAIL")
        diff = np.zeros_like(py_int, dtype=np.int32)
        diff[mask] = rtl_int[mask] - py_int[mask]
        print_fmap(f"Difference (RTL - Python) for {name}", diff)


# ------------------------------------------------------------
# Stage printing
# ------------------------------------------------------------
def print_all_python_stages(py_conv_raw, py_relu, py_quant, py_pool_dense):
    print("\n" + "=" * 80)
    print("FULL STAGE DEBUG (PYTHON GOLDEN MODEL)")
    print("=" * 80)

    for ch in range(4):
        print(f"\n================ CHANNEL {ch} ================\n")
        print("---- CONV (RAW, 6x6) ----")
        print(py_conv_raw[ch])

        print("\n---- RELU (6x6) ----")
        print(py_relu[ch])

        print("\n---- QUANTIZED (6x6) ----")
        print(py_quant[ch])

        print("\n---- MAXPOOL DENSE 2x2 STRIDE2 (3x3) ----")
        print(py_pool_dense[ch])


# ------------------------------------------------------------
# RTL window parsing / presentation
# ------------------------------------------------------------
def parse_window_rows(data: np.ndarray):
    rows = []
    for entry in data:
        row_idx = int(entry[0])
        col_idx = int(entry[1])

        win_I = entry[2:11].reshape(3, 3)
        win_Q = entry[11:20].reshape(3, 3)

        rows.append(
            {
                "row": row_idx,
                "col": col_idx,
                "I": win_I,
                "Q": win_Q,
            }
        )
    return rows


def expected_python_window(
    img_I: np.ndarray,
    img_Q: np.ndarray,
    row_idx: int,
    col_idx: int,
):
    r0 = row_idx - 2
    c0 = col_idx - 2
    if r0 < 0 or c0 < 0 or r0 + 3 > img_I.shape[0] or c0 + 3 > img_I.shape[1]:
        return None, None
    return img_I[r0:r0+3, c0:c0+3], img_Q[r0:r0+3, c0:c0+3]


def print_window_debug(window_rows, img_I, img_Q, limit=None):
    print("\n" + "=" * 80)
    if limit is None:
        print(f"RTL WINDOW DEBUG (showing ALL {len(window_rows)} windows)")
    else:
        print(f"RTL WINDOW DEBUG (showing first {min(limit, len(window_rows))} windows)")
    print("=" * 80)

    if len(window_rows) == 0:
        print("[INFO] No rtl_windows.txt entries found.")
        return

    iterable = window_rows if limit is None else window_rows[:limit]

    for idx, item in enumerate(iterable):
        row_idx = item["row"]
        col_idx = item["col"]
        rtl_I = item["I"]
        rtl_Q = item["Q"]
        exp_I, exp_Q = expected_python_window(img_I, img_Q, row_idx, col_idx)

        print(f"\n--- Window #{idx} at RTL row={row_idx}, col={col_idx} ---")

        print("\nRTL I window:")
        print(rtl_I)

        print("\nRTL Q window:")
        print(rtl_Q)

        if exp_I is not None:
            print("\nExpected Python I window:")
            print(exp_I)

            print("\nExpected Python Q window:")
            print(exp_Q)

            print("\nDifference I (RTL - Python):")
            print(rtl_I - exp_I)

            print("\nDifference Q (RTL - Python):")
            print(rtl_Q - exp_Q)

            if np.array_equal(rtl_I, exp_I) and np.array_equal(rtl_Q, exp_Q):
                print("\nMATCH: YES")
            else:
                print("\nMATCH: NO")
        else:
            print("\nExpected Python window: out of range")


# ------------------------------------------------------------
# Stream-style RTL presentation
# ------------------------------------------------------------
def print_stream_entries(data: np.ndarray, label: str, limit=None):
    print("\n" + "=" * 80)
    if limit is None:
        print(f"{label} (showing ALL {len(data)} entries)")
    else:
        print(f"{label} (showing first {min(limit, len(data))} entries)")
    print("=" * 80)

    if data.shape[0] == 0:
        print("[INFO] No entries.")
        return

    iterable = data if limit is None else data[:limit]

    for i, (ch, row, col, val) in enumerate(iterable):
        print(f"{i:03d}: ch={int(ch)} row={int(row)} col={int(col)} val={int(val)}")


def print_raw_conv_grouped_by_spatial(data: np.ndarray):
    print("\n" + "=" * 80)
    print("RTL RAW CONV GROUPED BY SPATIAL LOCATION")
    print("=" * 80)

    if data.shape[0] == 0:
        print("[INFO] No raw conv entries.")
        return

    grouped = defaultdict(dict)
    for ch, row, col, val in data:
        grouped[(int(row), int(col))][int(ch)] = int(val)

    for (row, col) in sorted(grouped.keys()):
        ch_map = grouped[(row, col)]
        print(f"(row={row}, col={col}) -> "
              f"ch0={ch_map.get(0, '.')}, "
              f"ch1={ch_map.get(1, '.')}, "
              f"ch2={ch_map.get(2, '.')}, "
              f"ch3={ch_map.get(3, '.')}")


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
def main():
    rtl_pool_data = load_rtl_output("rtl_out.txt")
    rtl_conv_quant_data = load_conv_dump("rtl_conv_out.txt")
    rtl_conv_raw_data = load_conv_raw_dump("rtl_conv_raw.txt")
    rtl_window_data = load_window_dump("rtl_windows.txt")

    img_I, img_Q = build_input_images()
    weights = get_weights()

    py_conv_raw = conv2d_iq(img_I, img_Q, weights)
    py_relu = relu(py_conv_raw)
    py_quant = quantize_int16(py_relu)
    py_pool_dense = maxpool2x2_stride2_dense(py_quant)

    print_all_python_stages(py_conv_raw, py_relu, py_quant, py_pool_dense)

    parsed_windows = parse_window_rows(rtl_window_data)
    print_window_debug(parsed_windows, img_I, img_Q, limit=None)

    print_stream_entries(rtl_conv_raw_data, "RTL RAW CONV STREAM", limit=64)
    print_raw_conv_grouped_by_spatial(rtl_conv_raw_data)
    print_stream_entries(rtl_conv_quant_data, "RTL QUANTIZED CONV STREAM", limit=64)
    print_stream_entries(rtl_pool_data, "RTL POOL STREAM", limit=64)

    rtl_conv_quant_fmap = reconstruct_stage_fmap(
        rtl_conv_quant_data, num_channels=4, rows=6, cols=6
    )
    rtl_conv_raw_fmap = reconstruct_stage_fmap(
        rtl_conv_raw_data, num_channels=4, rows=6, cols=6
    )

    py_conv_raw_rtl_order = remap_python_channels_to_rtl(py_conv_raw)
    py_quant_rtl_order = remap_python_channels_to_rtl(py_quant)

    compare_sparse_maps("Raw Conv Feature Map (RTL Channel Order)", rtl_conv_raw_fmap, py_conv_raw_rtl_order)
    compare_sparse_maps("Quantized Conv Feature Map (RTL Channel Order)", rtl_conv_quant_fmap, py_quant_rtl_order)

    print("\n" + "#" * 80)
    print("POOL OUTPUT CHECK")
    print("#" * 80)

    if rtl_pool_data.shape[0] == 0:
        print("[INFO] rtl_out.txt is empty: no pooled RTL outputs were generated.")
        print("[INFO] Raw and quantized conv analysis above is still valid.")
        return

    rtl_pool_fmap = reconstruct_pool_fmap(rtl_pool_data, num_channels=4, rows=3, cols=3)
    py_pool_dense_rtl_order = remap_python_channels_to_rtl(py_pool_dense)

    compare_dense_maps("Pooled Feature Map (RTL Channel Order)", rtl_pool_fmap, py_pool_dense_rtl_order)


if __name__ == "__main__":
    main()