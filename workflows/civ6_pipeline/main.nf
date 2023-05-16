workflowDir = params.rootDir + "/workflows"
targetDir = params.rootDir + "/target/nextflow"

include { plot_map } from targetDir + '/civ6_save_renderer/plot_map/main.nf'
include { combine_plots } from targetDir + '/civ6_save_renderer/combine_plots/main.nf'
include { convert_plot } from targetDir + '/civ6_save_renderer/convert_plot/main.nf'
include { parse_header } from targetDir + '/civ6_save_renderer/parse_header/main.nf'
include { parse_map } from targetDir + '/civ6_save_renderer/parse_map/main.nf'

include { readConfig; channelFromParams; helpMessage; preprocessInputs; mergeMap } from workflowDir + "/utils/WorkflowHelper.nf"
include { initState; toState; fromState; prettyFormat } from workflowDir + "/utils/StateHelper.nf"

config = readConfig("$workflowDir/civ6_pipeline/config.vsh.yaml")
// println(prettyFormat(config))

workflow {
  helpMessage(config)

  channelFromParams(params, config)
    | view
    | run_wf
}

workflow run_wf {
  take:
  input_ch

  main:
  output_ch = input_ch

    | preprocessInputs("config": config)

    // initialize the state
    | initState
    // Put the framerate aside for later:
    | toState{ id, data, state -> [ combine_plots: [ framerate: data.framerate ] ] }

    // Run in parallel
    | ( parse_header & parse_map )
    | join

    // 
    | map { id, header, state1, map, state2 -> 
      def new_data = [ "yaml" : header, "tsv": map ]
      [ id, new_data, state1 ] 
    }
    | view{ prettyFormat(it) }
    | plot_map

    | convert_plot

    | toSortedList{ a,b -> a[0] <=> b[0] }
    | map { tuples -> 
      new_data = [ input: tuples.collect{ it[1] }, output: "final.webm" ]
      [ "final", new_data, tuples[0][2] ] 
    }

    | fromState{ id, data, state -> mergeMap(data, state.combine_plots) }
    | combine_plots.run(
        auto: [ publish: true ]
    )

  emit:
  output_ch
}
