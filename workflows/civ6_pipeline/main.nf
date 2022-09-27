nextflow.enable.dsl=2

workflowDir = params.rootDir + "/workflows"
targetDir = params.rootDir + "/target/nextflow"


include { plot_map } from targetDir + '/civ6_save_renderer/plot_map/main.nf'
include { combine_plots } from targetDir + '/civ6_save_renderer/combine_plots/main.nf'
include { convert_plot } from targetDir + '/civ6_save_renderer/convert_plot/main.nf'
include { parse_header } from targetDir + '/civ6_save_renderer/parse_header/main.nf'
include { parse_map } from targetDir + '/civ6_save_renderer/parse_map/main.nf'

include { readConfig; viashChannel; helpMessage } from workflowDir + "/utils/WorkflowHelper.nf"

config = readConfig("$workflowDir/civ6_pipeline/config.vsh.yaml")

workflow {
  helpMessage(config)

  Channel.fromPath(params.input)
    | map{ [ it.baseName, [ input: it ] ] }
    | view { "Input: $it" }
    | run_wf
    | view { "Output: $it" }
}

workflow run_wf {
  take:
  input_ch

  main:
  output_ch = input_ch
    | ( parse_header & parse_map )
    | join
    | map { id, header, map ->
            [ id, [ "yaml" : header, "tsv": map ] ] }
    | plot_map
    | convert_plot
    | toSortedList{ a,b -> a[0] <=> b[0] }
    | map { tuples -> [ "final", [ input: tuples.collect{it[1] }, output: "final.webm" ] ] }
    | combine_plots.run(
        auto: [ publish: true ]
    )

  emit:
  output_ch
}
