#!/bin/bash
#SBATCH --job-name=jupyter-lab
#SBATCH --time=5-00:00:00   # days-hours:minutes:seconds
#SBATCH --ntasks=1          
#SBATCH --cpus-per-task=8   # per sciwiki, use CPUs to inform mem. 1 CPU = 4 Gb
#SBATCH --mem-per-cpu=4G
#SBATCH --output=jupyter-lab.job.out
#SBATCH --error=jupyter-lab.job.err

module purge
module load Apptainer

# Select a more secure password if desired
export APPTAINERENV_JUPYTER_PASSWORD="" # $(openssl rand -base64 15)

## Container image path - local SIF file or GHCR image
## local
# export IMAGE_PATH="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/jupyter-lab-launcher/images/jupyter-datascience-notebook.sif"
## or use apptainer pull to download the image from GHCR
## use 'ORAS' protocol for SIFs, and 'docker' for Docker images
export IMAGE_PATH="oras://ghcr.io/fred-hutch-innovation-lab/jupyter-lab-launcher:0.0.3"


workdir=$(mktemp -d)
export APPTAINERENV_USER=$(id -un)

CONFIG_FILE="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/jupyter-lab-launcher/users/${USER}/jupyter_lab_config.py"
# Check if custom config exists, otherwise use default
if [ -f "${CONFIG_FILE}" ]; then
    CONFIG_ARG="--config=${CONFIG_FILE}"
    echo "Using custom config: $CONFIG_ARG"
else
    CONFIG_ARG=""
    echo "No custom config found, using default Jupyter Lab configuration"
fi

# Get an available port
export PORT=$(fhfreeport)

cat 2>&1 <<END
Jupyter Lab is starting up...

Container Information:
- Image: ${IMAGE_PATH}

Connection Information:
- URL: http://$(hostname).fhcrc.org:${PORT}
- Password: ${APPTAINERENV_JUPYTER_PASSWORD}

Once the server is running, you can access it directly from your browser at the URL above.
Make sure you're connected to the VPN if accessing from outside the network.

When done using Jupyter Lab, terminate the job by:

1. Close all Jupyter notebooks and stop the kernel
2. Issue the following command on the login node:

      scancel -f ${SLURM_JOB_ID}

Note that if the server is not available despite the job running, it may be because
the image is being downloaded. Check the error log to see if it's still pulling.
END

# Launch Jupyter Lab with Apptainer
apptainer exec --cleanenv \
                 --scratch /run,/tmp \
                 --workdir $(mktemp -d) \
                 --bind /home:/home \
                 --bind /fh:/fh \
                 ${IMAGE_PATH} \
   jupyter lab ${CONFIG_ARG} \
               --port=${PORT} \
               --ip=0.0.0.0 \
               --no-browser \
               --allow-root \
               --NotebookApp.token='' \
               --NotebookApp.password=${APPTAINERENV_JUPYTER_PASSWORD}
