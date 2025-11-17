# f2c / libf2c – ビルド & 保守ガイド

このリポジトリは、レガシーな Fortran→C 変換ツール **f2c** と、その実行時ライブラリ **libf2c** を、現代的な CMake でビルド・インストール・テスト可能にするための構成を提供します。新機能の追加は行わず、**保守性・再現性・最小改修**を重視します。

> 目的:
> - 上流ソースは古い Makefile 前提のため、**最新コンパイラ/ツールチェーンで安定ビルド**できるようにする
> - 取得方法は「**手元のアーカイブを優先**、なければ **オンライン取得**」(Mode B)
> - 生成物は **ビルドツリーへ隔離**（ソースツリーは汚さない）

---

## 1. ディレクトリ構成

```
.
├─ CMakeLists.txt
├─ cmake/                    # 共通CMakeモジュール (FetchAndUnpack 等)
├─ archives/                 # 手元アーカイブ (src.tgz / libf2c.zip 等)
├─ tests/                    # smoke (E2E) tests
│  ├─ CMakeLists.txt
│  └─ cases/
│     ├─ 01_hello/
│     │  ├─ hello.f
│     │  └─ expected.txt     # 正規表現（前後空白を許容等）
│     ├─ 02_print_int/
│     └─ 03_sum/
└─ build/                    # ← 生成物（ユーザー生成。版管理対象外）
   ├─ unpacked_sources/      # 上流ソース展開先（libf2c, f2c_src）
   ├─ generated/             # 生成ヘッダ（arith.h, f2c.h など）
   └─ tests/                 # 各ケースの作業領域（.c, 実行ファイル, ログ）
```

- **ソースツリー**は常にクリーン: 展開物や生成物は `build/` 配下にのみ出力します。
- `archives/` は **オフライン配布**や **社内共有**向け（GitHub 公開時は上流アーカイブを含めない運用を想定）。
- `.cache/downloads/` は自動取得したアーカイブのキャッシュ先です（削除すると再取得します）。

---

## 2. 前提ツール

- CMake 3.20+
- C コンパイラ（GCC / Clang など）
- make / ninja 等のビルドツール
- （オンライン取得時）curl 等

> **Note (English):** The project is tested on macOS and Linux toolchains. Windows support is not a target at the moment.

---

## 3. ビルド & インストール（標準手順）

```bash
# Configure (オフライン優先、テスト有効)
cmake -S . -B build -DNET_FETCH=OFF -DBUILD_TESTING=ON

# Build
cmake --build build --parallel

# Install（ユーザー領域例）
cmake --install build --prefix "$HOME/.local"   # ~/.local/bin に f2c が入る

# Uninstall
cmake --build build --target uninstall
```

> **Permission:** `/usr/local` などシステム領域へ入れる場合は `sudo cmake --install build`。ユーザー領域（`~/.local`）を推奨。

---

## 4. 取得モード（Mode B）とハッシュ固定

このプロジェクトは **Mode B**（手元アーカイブ優先→無ければオンライン取得）で動作します。

- 手元にアーカイブがある場合（推奨）: `archives/` に次のファイル名で配置します。
  - `src.tgz`（f2c 本体ソース）
  - `libf2c.zip`（ランタイムソース）
- オンライン取得を許可する場合: `-DNET_FETCH=ON` で構成します（自動取得分は `.cache/downloads/` に保存されます）。

### ハッシュ固定

再現性のため、上流アーカイブの **SHA256** を CMake に固定します。

```bash
# Hash calculation
shasum -a 256 archives/src.tgz     | awk '{print $1}'
shasum -a 256 archives/libf2c.zip  | awk '{print $1}'
```
上記の値を `CMakeLists.txt` の以下の変数に反映してください。

```cmake
set(F2C_SRC_SHA256  "<PUT_SHA256_FOR_src.tgz>")
set(LIBF2C_SHA256   "<PUT_SHA256_FOR_libf2c.zip>")
```

オンライン経由の検証は次の通りです（ダウンロード→ハッシュ検証→ビルド）。

```bash
# 一時的に手元のアーカイブを退避し、オンライン取得で検証
mkdir -p /tmp/f2c_archives_backup
mv archives/src.tgz    /tmp/f2c_archives_backup/
mv archives/libf2c.zip /tmp/f2c_archives_backup/

rm -rf build
cmake -S . -B build -DNET_FETCH=ON
cmake --build build
```

> **Tip (English):** If the online hash does not match the fixed one, configuration will fail immediately to protect reproducibility.

---

## 5. CMake ターゲットとクリーン段階

### 主ターゲット
- `f2c` : Fortran→C 変換ツール本体（実行ファイル）
- `f2c_runtime` : ランタイムライブラリ（静的）
- `xsum` : 上流の補助ツール（利用環境に応じて）

### 補助ターゲット
- `unpack` : アーカイブ展開（`resolve_input_file`/`add_unpack_target` が登録）
- `uninstall` : 既存のインストールを削除（`cmake/Uninstall.cmake.in` 利用）
- `clean_downloads` : `build/unpacked_sources`, `build/generated`, `.cache/downloads` をまとめて削除

```bash
# Examples
cmake --build build --target clean
cmake --build build --target clean_downloads
cmake --build build --target uninstall
```

---

## 6. テスト（スモーク / E2E）

このリポジトリには **最小限の E2E スモークテスト** が含まれます。各ケースは `.f` を変換→リンク→実行し、**標準出力が期待値と一致**することを検証します。

```bash
# Run all smoke tests
ctest --test-dir build -L smoke --output-on-failure -j$(sysctl -n hw.ncpu 2>/dev/null || nproc)

# Run a single test
ctest --test-dir build -R '^01_hello$' --output-on-failure

# Re-run only failed
ctest --test-dir build --rerun-failed --output-on-failure
```

### 追加方法（ケースを増やす）
1. `tests/cases/NN_name/` を作成
2. Fortran 固定形式の `.f` と、期待出力の正規表現 `expected.txt` を配置
3. `tests/CMakeLists.txt` に `add_f2c_case(NN_name file.f expected.txt)` を1行追加

> **Design notes (English):** Tests run in dedicated working directories under `build/tests/…`, keeping the source tree clean. Locale is fixed via `LC_ALL=C;TZ=UTC`. Floating-point output is avoided in smoke tests.

---

## 7. トラブルシューティング

- **`I/O error on c_file`**
  - 意味: 生成される C ファイルへの書き込みに失敗
  - 代表例: 権限不足／出力先の存在しないディレクトリ／標準入力経由なのに標準出力をファイルへリダイレクトしていない
  - 対処: 作業ディレクトリの権限と存在を確認。テストでは標準出力をファイルに保存する実装にしてあります。

- **`Warning on line N: missing final end statement`**
  - 意味: ファイル末尾までに `END` 文が検出できなかった
  - 代表例: 固定形式の桁位置ずれ、末尾の改行欠落、不可視文字の混入
  - 対処: `PROGRAM ...` / `PRINT ...` / `END` の形で、**末尾改行あり**の固定形式ソースにする

- **`file INSTALL cannot copy ... Permission denied`**
  - 意味: `/usr/local` など書き込み不可の場所にインストールしようとした
  - 対処: `--prefix "$HOME/.local"` を使うか、`sudo` で実行

- **`INSTALL(EXPORT) given unknown export`**
  - 意味: `install(EXPORT ...)` の export 名と `install(TARGETS ... EXPORT ...)` が不整合
  - 対処: CMakeLists の export 名を揃える

---

## 8. メンテナンス方針

- 範囲: **バグ修正** と **新規環境（OS/コンパイラ/パッケージ管理）対応** のみ。新機能追加は行いません。
- 上流更新フロー:
  1) 新アーカイブを取得 → `archives/` に配置
  2) SHA256 を計算して `CMakeLists.txt` のハッシュを更新
  3) `-DNET_FETCH=ON` でオンライン検証 → ビルド・テスト通過
  4) タグ付け / リリースノート更新（ハッシュ値と上流の変更点を記載）
- 命名と公開 API:
  - CMake ターゲット名（`f2c`, `f2c_runtime` 等）は**安定化**し、後方互換を維持
  - 生成ヘッダやツールは `build/generated/` に集約

> **License note:** 上流ソースのライセンス条件を尊重してください。GitHub 公開時は上流アーカイブを含めず、この README の「取得モード」節に従ってビルドしてください。

---

## 9. クイックリファレンス（よく使うコマンド）

```bash
# Configure → Build → Install (user-local)
cmake -S . -B build -DNET_FETCH=OFF -DBUILD_TESTING=ON
cmake --build build --parallel
cmake --install build --prefix "$HOME/.local"

# Cleanup / Uninstall
cmake --build build --target clean
cmake --build build --target clean_downloads
cmake --build build --target uninstall

# Tests
ctest --test-dir build -L smoke --output-on-failure -j$(sysctl -n hw.ncpu 2>/dev/null || nproc)
```
