#!/bin/bash

# automatically export the workflow helper
viash export resource platforms/nextflow/ProfilesHelper.config > workflows/utils/ProfilesHelper.config
viash export resource platforms/nextflow/WorkflowHelper.nf > workflows/utils/WorkflowHelper.nf
viash export resource platforms/nextflow/DataflowHelper.nf > workflows/utils/DataflowHelper.nf

