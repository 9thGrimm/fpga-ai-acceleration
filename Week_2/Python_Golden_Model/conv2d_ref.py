from __future__ import annotations
import numpy as np

def conv2d_valid(x: np.ndarray, k: np.ndarray) -> np.ndarray:
    """
    2D convolution (VALID) with a single channel.
    x: (H, W)
    k: (Kh, Kw)
    returns: (H-Kh+1, W-Kw+1)
    """
    if x.ndim != 2 or k.ndim != 2:
        raise ValueError("x and k must be 2D arrays")
    H, W = x.shape
    Kh, Kw = k.shape
    Oh, Ow = H - Kh + 1, W - Kw + 1
    if Oh <= 0 or Ow <= 0:
        raise ValueError("Kernel must be smaller than input for VALID conv")

    y = np.zeros((Oh, Ow), dtype=np.int64)

    for i in range(Oh):
        for j in range(Ow):
            acc = 0
            for ki in range(Kh):
                for kj in range(Kw):
                    acc += int(x[i + ki, j + kj]) * int(k[ki, kj])
            y[i, j] = acc
    return y

def main() -> None:
    x = np.arange(64, dtype=np.int64).reshape(8, 8)
    k = np.array([
        [ 1,  0, -1],
        [ 2,  0, -2],
        [ 1,  0, -1],
    ], dtype=np.int64)  # Sobel-like kernel

    y = conv2d_valid(x, k)

    print("Input x (8x8):")
    print(x)
    print("\nKernel k (3x3):")
    print(k)
    print("\nOutput y (6x6) VALID:")
    print(y)

    np.savetxt("x_8x8.txt", x, fmt="%d")
    np.savetxt("k_3x3.txt", k, fmt="%d")
    np.savetxt("y_6x6.txt", y, fmt="%d")
    print("\nSaved: x_8x8.txt, k_3x3.txt, y_6x6.txt")

if __name__ == "__main__":
    main()
