#!/bin/bash
rsync -avzh ./ jmif9945@hpc.sydney.edu.au:/project/jcomvirome/JCOM_pipeline_virome/scripts/
ssh jmif9945@hpc.sydney.edu.au 'chmod +x /project/jcomvirome/JCOM_pipeline_virome/scripts/*'
