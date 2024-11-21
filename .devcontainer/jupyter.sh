#!/bin/bash
# source /home/glue_user/.bashrc
set -e

if [[ -z $(pgrep -f jupyter-lab) ]]; then
    echo "Starting Livy and JupyterLab"
    
    # Starting Livy Server
    livy-server start
    
    # Starting JupyterLab
    jupyter lab \
        --no-browser \
        --ip=0.0.0.0 \
        --port=8889 \
        --allow-root \
        --InlineBackend.figure_formats='{"png", "jpeg", "svg", "pdf"}' \
        --FileContentsManager.delete_to_trash=False \
        --ServerApp.allow_origin='*' \
        --ServerApp.root_dir=/home/glue_user/workspace/ \
        --ServerApp.token='' \
        --ServerApp.password='' \
        --ServerApp.logging_config='{
            "version": 1,
            "handlers": {
                "file": {
                    "class": "logging.FileHandler",
                    "filename": "/home/glue_user/jupyter/logs/jupyterlab.log",
                    "level": "INFO"
                }
            },
            "root": {
                "handlers": ["file"],
                "level": "INFO"
            }
        }'
    
    echo "JupyterLab started and logging to /home/glue_user/jupyter/logs/jupyterlab.log"
else
    echo "JupyterLab is already running"
fi