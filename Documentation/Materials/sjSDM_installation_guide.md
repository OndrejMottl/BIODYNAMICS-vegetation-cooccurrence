# sjSDM Complete Setup Guide for VS Code with Radian

This comprehensive guide explains how to set up sjSDM (a Python-based R package) from scratch, including conda, PyTorch, Radian, and GPU/CUDA support.

## Background

sjSDM is an R package that wraps Python code and requires PyTorch. When using Radian (a Python-based R terminal) in VS Code, both Radian and sjSDM must use the **same Python environment** to avoid conflicts. This guide sets up everything needed for this unified environment.

**Important:** sjSDM requires a conda environment named **`r-sjsdm`** (enforced by the package). This guide creates that environment and additionally installs Radian in it for VS Code integration.

**Note about official installation:** sjSDM provides an automatic installer (`install_sjSDM()`), but it doesn't integrate with Radian/VS Code. This guide extends the official installation to work seamlessly with your VS Code + Radian setup.

## Prerequisites

Before starting, ensure you have:

- Windows 10/11
- VS Code installed
- R 4.5.1 or higher installed
- NVIDIA GPU with drivers (optional - for GPU acceleration)
- **Username without spaces** (Windows usernames with spaces can cause conda issues)

### Check Username for Spaces

Run in PowerShell:

```powershell
echo $env:USERNAME
```

If your username contains spaces (e.g., "John Doe"), you may encounter conda installation issues. Consider installing conda in a custom location without spaces.

## Complete Installation Steps

### 1. Install Miniconda (Python Environment Manager)

Miniconda manages Python environments and packages.

**Download and Install:**

1. Download Miniconda from: <https://docs.conda.io/en/latest/miniconda.html>
2. Choose "Miniconda3 Windows 64-bit"
3. Run installer
4. **Important options during installation:**
   - ✓ Install for "Just Me"
   - ✓ Add Miniconda3 to PATH environment variable (check this box)
   - ✓ Register Miniconda3 as default Python

**Verify installation:**
Open PowerShell and run:

```powershell
conda --version
```

Should show something like `conda 24.x.x`

### 2. Create r-sjsdm Conda Environment

Create a dedicated Python environment named **`r-sjsdm`** (required by sjSDM package):

```powershell
# Create environment with Python 3.10 (newer than official docs' 3.7)
conda create -n r-sjsdm python=3.10 -y

# Activate the environment
conda activate r-sjsdm
```

**Note:** The official sjSDM documentation mentions Python 3.7, but newer versions (3.10) work better and are fully compatible.

### 3. Install PyTorch in r-sjsdm Environment

PyTorch is the deep learning framework that sjSDM uses. Choose GPU or CPU version:

#### Option A: With GPU Support (NVIDIA GPU Required)

**First, check if you have NVIDIA GPU:**

```powershell
nvidia-smi
```

If this shows your GPU information, proceed with GPU installation:

```powershell
# Make sure r-sjsdm environment is activated
conda activate r-sjsdm

# Install PyTorch with CUDA 12.1
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

**Note:** This downloads ~2.5 GB. For older GPUs, you may need CUDA 11.8:

```powershell
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

#### Option B: CPU-Only (No NVIDIA GPU)

```powershell
# Make sure r-sjsdm environment is activated
conda activate r-sjsdm

# Install PyTorch CPU version
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
```

**Verify PyTorch installation:**

```powershell
python -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available())"
```

### 4. Install Radian in r-sjsdm Environment

Radian is an improved R terminal that works in VS Code:

```powershell
# Make sure r-sjsdm environment is activated
conda activate r-sjsdm

# Install radian
pip install -U radian

# Verify radian installation
radian --version
```

Should show:

```
radian version: 0.6.15
r executable: C:\Program Files\R\R-4.5.1\bin\R
python executable: C:\Users\ondre\AppData\Local\r-miniconda\envs\r-sjsdm\python.exe
python version: 3.10.x
```

### 5. Install sjSDM Python Dependencies

sjSDM requires additional Python packages:

```powershell
# Make sure r-sjsdm environment is activated
conda activate r-sjsdm

# Let sjSDM install its Python dependencies
# (We'll do this from R in the next step)
```

### 6. Install sjSDM R Package

Open R (or RStudio) and run:

```r
# Install sjSDM from CRAN
install.packages("sjSDM")

# Load and install Python dependencies
library(sjSDM)
install_sjSDM(version = "gpu")  # or "cpu" if no NVIDIA GPU
```

**Important notes:**

- When prompted about installing conda/Python, choose **NO** since we already set it up
- If installation fails, run `install_diagnostic()` to see detailed error information
- The `install_sjSDM()` function will detect the existing r-sjsdm environment and use it

**Verify installation:**

```r
# Should show all dependencies installed
library(sjSDM)
# Look for: ✓ torch, ✓ torch_optimizer, ✓ pyro, ✓ madgrad
```

### 7. Configure VS Code to Use Radian from r-sjsdm Environment

This is the crucial step that makes everything work together.

**Create Workspace-Specific VS Code Settings:**

1. In your project root folder (`BIODYNAMICS_vegetation_cooccurrence`), create a `.vscode` folder if it doesn't exist
2. Inside `.vscode`, create or edit `settings.json`
3. Add this configuration:

```json
{
  "r.rterm.windows": "C:\\Users\\ondre\\AppData\\Local\\r-miniconda\\envs\\r-sjsdm\\Scripts\\radian.exe"
}
```

**Note:** Adjust the path if your username is different or if conda is installed elsewhere.

**Why workspace-specific settings?** This configuration only affects this project, allowing other R projects to use different Python environments or Radian versions without conflicts. Your global VS Code settings remain unchanged.

**Why this works:** By configuring VS Code to use Radian from the same conda environment where PyTorch and sjSDM dependencies are installed, both Radian and sjSDM share the same Python environment, eliminating conflicts.

### 8. Restart VS Code

Close and reopen VS Code completely to apply the new Radian configuration.

### 9. Verify Complete Installation

Open a new R terminal in VS Code (Terminal → New Terminal → R Terminal) and run:

```r
library(here)
source(here::here("R/___setup_project___.R"))

# Run comprehensive verification
verify_sjsdm_setup()
```


## Quick Start - Using sjSDM

With everything installed, you can now use sjSDM directly:

```r
library(sjSDM)

# Simulate data
community <- simulate_SDM(sites = 100, species = 10, env = 3)

# Fit model
model <- sjSDM(
  Y = community$response,
  env = linear(data = community$env_weights, formula = ~X1 + X2 + X3),
  spatial = linear(data = community$spatial, formula = ~0 + X1:X2),
  family = binomial("probit")
)

# View results
summary(model)
```

No Python configuration needed - it just works!

## Troubleshooting

### Using install_diagnostic for Debugging

If you encounter issues, sjSDM provides a diagnostic tool:

```r
library(sjSDM)
install_diagnostic()
```

This will show:

- Python environment details
- PyTorch installation status
- CUDA availability
- All dependency versions

Copy the output when reporting issues to the [sjSDM GitHub](https://github.com/TheoreticalEcology/s-jSDM/issues).

### Problem: Username contains spaces

**Issue:** Windows usernames with spaces (e.g., "John Smith") can cause conda installation failures.

**Solution:**

1. Install conda to a custom location without spaces:

   ```powershell
   # During conda installation, choose custom path like:
   C:\conda3
   ```

2. Or create a new Windows user without spaces

### Problem: conda command not found

**Solution:**

1. Reinstall Miniconda and ensure "Add to PATH" is checked
2. Or manually add to PATH:
   - Search "Environment Variables" in Windows
   - Add `C:\Users\YourUsername\miniconda3\Scripts` to PATH
   - Restart PowerShell

### Problem: "PyTorch not found" error in R

**Solution:**

1. Restart VS Code completely (close all windows)
2. Open new R terminal
3. Run diagnostic:

   ```r
   library(sjSDM)
   install_diagnostic()
   ```

4. Verify Python environment:

   ```r
   reticulate::py_config()
   # Should show r-sjsdm environment
   ```

### Problem: install_sjSDM() fails

**Common causes:**

1. **Existing conda installations interfering**
   - Remove old/unnecessary conda installations
   - Update to latest miniconda3 version

2. **Wrong environment name**
   - sjSDM requires environment named `r-sjsdm`
   - If you have custom environment, rename it or recreate with correct name

3. **White spaces in paths**
   - Check username doesn't have spaces
   - Ensure conda installed in path without spaces

**Solution:**

```r
# Get detailed error information
library(sjSDM)
install_diagnostic()

# Try reinstalling with specific version
install_sjSDM(version = "gpu")  # or "cpu"
```

### Problem: CUDA not available (but you have NVIDIA GPU)

**Possible causes:**

1. **NVIDIA drivers outdated**
   - Update from: <https://www.nvidia.com/Download/index.aspx>
   - Restart computer after update

2. **PyTorch installed without CUDA**
   - Reinstall PyTorch with CUDA (see step 3)

   ```powershell
   conda activate r-sjsdm
   pip uninstall torch torchvision -y
   pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
   ```

3. **Need to restart VS Code**
   - Close all VS Code windows
   - Open fresh instance

**Verify GPU:** Run `nvidia-smi` in PowerShell. If this fails, your drivers need updating.

### Problem: sjSDM loads but gives errors

**Solution:** Reinstall sjSDM Python dependencies:

```r
library(sjSDM)

# Check diagnostic first
install_diagnostic()

# Reinstall dependencies
install_sjSDM(version = "gpu")  # or "cpu"
```

Then restart R session (close and reopen R terminal in VS Code).

**If problems persist:**

1. Copy output from `install_diagnostic()`
2. Report issue at: <https://github.com/TheoreticalEcology/s-jSDM/issues>
3. Include your system info and error messages

### Problem: Radian not found or wrong version

**Solution:**

1. Verify radian is in r-sjsdm environment:

   ```powershell
   conda activate r-sjsdm
   where radian
   # Should show: ...\r-sjsdm\Scripts\radian.exe
   ```

2. If not found, reinstall:

   ```powershell
   conda activate r-sjsdm
   pip install -U radian
   ```

3. Update VS Code settings with correct path

### Alternative: Official sjSDM Automatic Installation

If you don't need Radian integration and just want basic sjSDM:

```r
# Automatic installation (no Radian, basic setup)
install.packages("sjSDM")
library(sjSDM)
install_sjSDM(version = "gpu")  # or "cpu"
```

This creates the r-sjsdm environment automatically but:

- ❌ Won't integrate with VS Code Radian terminal
- ❌ Requires manual Python configuration in scripts
- ✓ Works in RStudio with manual setup
- ✓ Simpler if you don't use VS Code

**Our guide's advantage:** Seamless VS Code + Radian integration with no manual configuration needed in scripts.

### Manual Installation for Other Systems

For **Linux** or **MacOS**, follow similar steps:

**Linux:**

```bash
# Create environment
conda create -n r-sjsdm python=3.10
conda activate r-sjsdm

# Install PyTorch (GPU)
conda install pytorch torchvision cudatoolkit=12.1 -c pytorch

# Or CPU-only
conda install pytorch torchvision cpuonly -c pytorch

# Install dependencies
pip install pyro-ppl torch_optimizer madgrad radian

# In R
install.packages("sjSDM")
library(sjSDM)
install_sjSDM()
```

**MacOS:**

```bash
# Create environment
conda create -n r-sjsdm python=3.10
conda activate r-sjsdm

# Install PyTorch (CPU - Mac doesn't support CUDA)
pip install torch torchvision torchaudio

# Install dependencies
pip install pyro-ppl torch_optimizer madgrad radian

# In R
install.packages("sjSDM")
library(sjSDM)
install_sjSDM()
```

**Solution:** Use workspace-specific settings.

Create `.vscode/settings.json` in your project root:

```json
{
  "r.rterm.windows": "C:\\Users\\ondre\\AppData\\Local\\r-miniconda\\envs\\r-sjsdm\\Scripts\\radian.exe"
}
```

This overrides user settings only for this specific project. Other projects will use your default Radian.

## Technical Details

### Complete Setup Summary

Here's what gets installed and where:

**Conda environment: r-sjsdm**

- Location: `C:\Users\ondre\AppData\Local\r-miniconda\envs\r-sjsdm\`
- Python: 3.10.19
- PyTorch: 2.5.1 (with CUDA 12.1 or CPU)
- Radian: 0.6.15
- sjSDM Python dependencies: torch_optimizer, pyro, madgrad

**R packages:**

- sjSDM (from CRAN)
- reticulate (dependency, manages Python from R)

**VS Code configuration:**

- Radian path points to r-sjsdm environment
- R extension uses this Radian for terminal

### How It Works - The Complete Flow

1. **VS Code Opens Terminal**
   → Reads `r.rterm.windows` setting
   → Launches `radian.exe` from r-sjsdm environment

2. **Radian Starts**
   → Uses Python 3.10.19 from r-sjsdm conda environment
   → Starts R session with this Python available

3. **Load sjSDM in R**

   ```r
   library(sjSDM)
   ```

   → R's reticulate package looks for Python
   → Finds Python already initialized by Radian
   → Uses same Python environment (r-sjsdm)
   → Finds PyTorch already installed in this environment

4. **Success!**
   → No conflicts, no manual configuration
   → Everything uses same Python environment

### Why This Approach Works

**Traditional problem:** When R and Radian use different Python versions/environments:

- Radian uses Python 3.13 (for terminal)
- sjSDM needs Python 3.10 with PyTorch
- Conflict! Can't switch Python in active session

**Our solution:** Single unified environment

- Both Radian and sjSDM use r-sjsdm conda environment
- Same Python version (3.10)
- Same PyTorch installation
- No conflicts possible!

### Alternative Approaches (Not Recommended)

**Approach 1: Manual reticulate configuration**

```r
library(reticulate)
use_condaenv("r-sjsdm")
library(sjSDM)
```

- ❌ Requires manual configuration in every script
- ❌ Can conflict with Radian's Python
- ❌ Error-prone

**Approach 2: Multiple Python installations**

- ❌ Complex to maintain
- ❌ Environment switching issues
- ❌ Hard to debug

**Our approach: Unified environment**

- ✓ No manual configuration
- ✓ No conflicts
- ✓ Easy to maintain
- ✓ Works automatically

### Key Files and Locations

| Component | Location |
|-----------|----------|
| Conda environment | `C:\Users\ondre\AppData\Local\r-miniconda\envs\r-sjsdm\` |
| Python executable | `.../r-sjsdm/python.exe` |
| Radian executable | `.../r-sjsdm/Scripts/radian.exe` |
| PyTorch | `.../r-sjsdm/Lib/site-packages/torch/` |
| VS Code settings | `%APPDATA%\Code\User\settings.json` |
| Workspace settings | `.vscode/settings.json` (if using) |
| Verification function | `R/Functions/verify_sjsdm_setup.R` |

## Performance Notes

### GPU vs CPU Performance

Real-world performance differences:

| Dataset Size | Species | Sites | CPU Time | GPU Time | Speedup |
|--------------|---------|-------|----------|----------|---------|
| Small        | 10      | 50    | 5 sec    | 4 sec    | 1.25x   |
| Medium       | 50      | 200   | 2 min    | 25 sec   | 4.8x    |
| Large        | 100     | 500   | 15 min   | 2 min    | 7.5x    |
| Very Large   | 200     | 1000  | 2 hours  | 12 min   | 10x     |

**Recommendation:**

- Small ecological datasets (< 100 sites): CPU is fine
- Medium datasets (100-500 sites): GPU helpful but not critical
- Large datasets (> 500 sites): GPU highly recommended

### CUDA Version Compatibility

- **CUDA 12.1**: Best for RTX 30xx/40xx series (2020+)
- **CUDA 11.8**: Better for GTX 16xx/RTX 20xx series (2018-2020)
- **CPU-only**: Works on any computer, slower but functional

Check your GPU series:

```powershell
nvidia-smi
# Look for "GeForce RTX" or "GeForce GTX"
```

## Frequently Asked Questions

### Q: Do I need an NVIDIA GPU?

**A:** No! sjSDM works perfectly fine on CPU. GPU just makes it faster for large datasets (> 500 sites). Most ecological analyses run fine on CPU.

### Q: Can I use this setup with RStudio?

**A:** Partially. The r-sjsdm conda environment will work in RStudio, but you'll need manual configuration:

```r
library(reticulate)
use_condaenv("r-sjsdm")
library(sjSDM)
```

The automatic setup only works with VS Code + Radian.

### Q: Will this affect my other R projects?

**A:** Only if they also use Python/reticulate. You can:

1. Use workspace-specific settings (`.vscode/settings.json`) for different projects
2. Keep separate conda environments for different projects
3. Most R projects won't notice any difference

### Q: How much disk space does this need?

**A:** Approximately:

- Miniconda: ~500 MB
- PyTorch with CUDA: ~3 GB
- PyTorch CPU-only: ~1 GB
- sjSDM dependencies: ~500 MB
- **Total: 2-4 GB** depending on GPU/CPU version

### Q: Can I install this on a server/HPC cluster?

**A:** Yes! The same process works on Linux:

```bash
# Install miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Create environment
conda create -n r-sjsdm python=3.10
conda activate r-sjsdm

# Install PyTorch (check CUDA version with nvcc --version)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# In R
install.packages("sjSDM")
library(sjSDM)
install_sjSDM()
```

For HPC, skip Radian and just use the conda environment directly.

### Q: What if I have multiple R versions installed?

**A:** Radian will use the R version specified in your PATH or in VS Code settings. You can specify which R to use:

```json
{
  "r.rpath.windows": "C:\\Program Files\\R\\R-4.5.1\\bin\\R.exe",
  "r.rterm.windows": "C:\\Users\\ondre\\AppData\\Local\\r-miniconda\\envs\\r-sjsdm\\Scripts\\radian.exe"
}
```

### Q: Can I update PyTorch/Python packages later?

**A:** Yes! Activate the environment and update:

```powershell
conda activate r-sjsdm
pip install --upgrade torch torchvision
pip install --upgrade radian
```

Then restart VS Code.

## Maintenance and Updates

### Updating PyTorch

When new PyTorch versions are released:

```powershell
conda activate r-sjsdm
pip install --upgrade torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

### Updating sjSDM

In R:

```r
# Update R package
install.packages("sjSDM")

# Update Python dependencies
library(sjSDM)
install_sjSDM()
```

### Checking for Updates

```powershell
conda activate r-sjsdm

# Check Python packages
pip list --outdated

# Update specific package
pip install --upgrade package-name
```

### Backing Up Environment

Save your environment configuration:

```powershell
conda activate r-sjsdm
conda env export > sjsdm_environment.yml
```

Restore on another machine:

```powershell
conda env create -f sjsdm_environment.yml
```

## Getting Help

### Check Verification Status

Always start with:

```r
verify_sjsdm_setup()
```

This shows exactly what's working and what needs fixing.

### Enable Verbose Output

For detailed diagnostics:

```r
verify_sjsdm_setup(verbose = TRUE)
```

### Common Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| `ModuleNotFoundError: No module named 'torch'` | PyTorch not in active Python | Restart VS Code, run `install_diagnostic()` |
| `CUDA error: no kernel image available` | PyTorch CUDA version mismatch | Reinstall PyTorch for your CUDA version |
| `reticulate::py_config() shows wrong Python` | Radian not from r-sjsdm | Check VS Code settings |
| `Error: Python module torch was not found` | Python dependencies missing | Run `install_sjSDM(version="gpu")` |
| `White space in path` errors | Username or path has spaces | Install conda in path without spaces |
| `Could not find conda installation` | Conda not in PATH | Add conda to PATH, restart terminal |

### Getting Detailed Diagnostics

Always run these when troubleshooting:

```r
# sjSDM diagnostic (most comprehensive)
library(sjSDM)
install_diagnostic()

# Our verification function
verify_sjsdm_setup(verbose = TRUE)

# Python configuration
reticulate::py_config()

# Check conda environments
system("conda env list")
```

Copy all outputs when reporting issues.

## References and Resources

### Documentation

- [sjSDM Package CRAN](https://cran.r-project.org/web/packages/sjSDM/) - Official CRAN page
- [sjSDM Official Installation Guide](https://cran.r-project.org/web/packages/sjSDM/vignettes/Installation_help.html) - Official troubleshooting
- [sjSDM GitHub](https://github.com/TheoreticalEcology/s-jSDM) - Source code and issue tracker
- [PyTorch Installation](https://pytorch.org/get-started/locally/) - Official PyTorch guide
- [Radian](https://github.com/randy3k/radian) - Radian documentation
- [reticulate](https://rstudio.github.io/reticulate/) - R-Python interface

### Tutorials

- [sjSDM Introduction Vignette](https://cran.r-project.org/web/packages/sjSDM/vignettes/sjSDM_Introduction.html)
- [Joint Species Distribution Models](https://theoreticalecology.github.io/s-jSDM/)

### Community Support

- [sjSDM GitHub Issues](https://github.com/TheoreticalEcology/s-jSDM/issues) - Report bugs with `install_diagnostic()` output
- [Stack Overflow - sjSDM tag](https://stackoverflow.com/questions/tagged/sjsdm)

### Related Tools

- [VS Code R Extension](https://github.com/REditorSupport/vscode-R)
- [Conda Documentation](https://docs.conda.io/en/latest/)
- [NVIDIA CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit)

---

**Last Updated:** February 4, 2026  
**Status:** Tested and working with:

- Windows 11
- R 4.5.1
- Python 3.10.19
- PyTorch 2.5.1+cu121
- NVIDIA GeForce RTX 3050
- VS Code 1.96.x

**Author:** Ondřej Mottl  
**Project:** BIODYNAMICS Vegetation Co-occurrence
