/**
  * Utility process to rename files according to the id.
  * This is done via a simple cp command.
  */
process rename {

  tag "${id}"
  echo { (params.debug == true) ? true : false }
  cache 'deep'
  stageInMode "symlink"
  input:
    tuple val(id), path(input), val(pars)
  output:
    tuple val("${id}"), path("${id}.${input}"), val(pars)
  script:
    """
    cp $input "${id}.${input}"
    """

}

def generateSummary() {
    summary = "\n"
    summary += "Command Line:\n  ${ workflow.commandLine }\n"
    summary += "Pipeline completed at: $workflow.complete\n"
    summary += "Workflow revision:     ${ workflow.revision }\n"
    summary += "Launch Dir:            ${ workflow.launchDir }\n"
    summary += "Work Dir:              ${ workflow.workDir }\n"
    summary += "Project Dir:           ${ workflow.projectDir }\n"
    summary += "Username:              ${ workflow.userName }\n"
    summary += "\n"

    summary
}

process storeSummary {

  input:
    val(content)

  output:
    path("summary.txt")

  publishDir "$params.logDir"

  afterScript 'echo Stored params...'

  shell:
  """
  echo "$content" > summary.txt
  """

}

import static groovy.json.JsonOutput.*

process storeParams {

  input:
    val(pars)

  output:
    path("params.txt")

  publishDir "$params.logDir"

  afterScript 'echo Stored params...'

  shell:
  def pp = prettyPrint(toJson(params))
  """
  echo "$pp" > params.txt
  """

}
