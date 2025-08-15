# Jupyter Lab on FHIL HPC

This directory contains scripts and configuration for running Jupyter Lab instances on the FHIL HPC cluster using Apptainer containers. There are simpler methods of running jupyter on the cluster, but the goal of this method is to give you more control over the system libraries needed to use certain packages, and relies on a more transferable compute environment for reproducible analyses. 

## Prerequisites

1. **Apptainer Image**: You need a Jupyter Lab Apptainer image (`.sif` file) placed in the `images/` directory, OR you can use cloud-hosted SIF files directly
2. **Directory Structure**: Ensure the following directory structure exists:
   ```
   jupyter-lab-launcher/
   ├── images/
   │   └── jupyter-datascience-notebook.sif  # Local image (optional)
   └── users/
       └── $USER/
           └── jupyter_lab_config.py         # Custom config (optional)
   ```

## Usage

### 1. Submit the SLURM Job

```bash
sbatch launch_jupyter_lab.sh
```

### 2. Monitor the Job

Check the job status and output:
```bash
squeue -u $USER
tail -f /home/$USER/jupyter-lab.job.$SLURM_JOB_ID.out
```

### 3. Access Jupyter Lab

Once the job is running, you'll see connection information in the stdout:
- URL: `http://<hostname>.fhcrc.org:<port>`
- Password: The generated password (if using password authentication)

### 4. Terminate the Job

When you're done:
1. Close all Jupyter notebooks and stop kernels
2. Cancel the SLURM job:
   ```bash
   scancel -f $SLURM_JOB_ID
   ```

## Configuration

The script automatically:
- Allocates 8 CPUs and 32GB RAM (configurable in SLURM directives)
- Sets a 5-day time limit
- Creates a temporary working directory
- Generates a random port using `fhfreeport`
- Mounts necessary directories (`/home`, `/fh`)
- Configures Jupyter Lab for remote access

## Container Image Options

### Option 1: Local SIF File (Recommended for Offline/Performance)
```bash
# Use a local SIF file in the images directory
export IMAGE_PATH="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/jupyter-lab-launcher/images/jupyter-datascience-notebook.sif"
```

### Option 2: Cloud-Hosted SIF (Recommended for Latest Versions)
```bash
# Use the packaged cloud SIF from this repository
export IMAGE_PATH="oras://ghcr.io/fred-hutch-innovation-lab/jupyter-lab-launcher:0.0.3"
```

## Customization

### Resource Allocation
Modify the SLURM directives at the top of `launch_jupyter_lab.sh`:
```bash
#SBATCH --cpus-per-task=4    # Increase CPU cores
#SBATCH --mem-per-cpu=8G     # Increase memory per CPU
#SBATCH --time=7-00:00:00    # Increase time limit
```

### Package Management

The image is designed to be minimal and lightweight. Package management is handled at by the user within the environment. Consider using Poetry or UV (python) or Renv (R) to manage lanaguage specific packages.

#### System Libraries
- Edit `jupyter-datascience-notebook.def` and uncomment needed system libraries
- Rebuild the image when system dependencies change

## Building Custom Images

### Customize an Image

You can directly [edit the Apptainer `.def`](https://apptainer.org/docs/user/1.0/build_a_container.html#building-containers-from-apptainer-definition-files) file to add dependencies. Once the definition file is updated, you can manually build the `.sif` with `apptainer build`, or you can trigger a `tagged release` of this repo and Github will publish an updated SIF for you.

### Converting Dockerfile to Definition File

If Apptainer definition file syntax is challenging, you can write a Dockerfile and convert it with [Singularity Python](https://singularityhub.github.io/singularity-cli/recipes).

```bash
ml fhPython
spython recipe ./jupyter-datascience-notebook.dockerfile > jupyter-datascience-notebook.def
```

## Cloud Container Registry

### GitHub Container Registry (GHCR)

This repository includes pre-built SIF files hosted on GHCR. A tagged release will trigger a new build.

`oras://ghcr.io/fred-hutch-innovation-lab/jupyter-lab-launcher:0.0.3`

## Dependencies

- SLURM job scheduler
- Apptainer/Singularity
- `fhfreeport` utility (FHIL-specific)
- Jupyter Lab Apptainer image
