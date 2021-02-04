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
