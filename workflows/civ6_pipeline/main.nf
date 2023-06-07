workflowDir = params.rootDir + "/workflows"
targetDir = params.rootDir + "/target/nextflow"

include { plot_map } from targetDir + '/civ6_save_renderer/plot_map/main.nf'
include { combine_plots } from targetDir + '/civ6_save_renderer/combine_plots/main.nf'
include { convert_plot } from targetDir + '/civ6_save_renderer/convert_plot/main.nf'
include { parse_header } from targetDir + '/civ6_save_renderer/parse_header/main.nf'
include { parse_map } from targetDir + '/civ6_save_renderer/parse_map/main.nf'
include { publish } from targetDir + "/utils/publish/main.nf"
include { aggregate } from targetDir + "/utils/aggregate/main.nf"
include { civ6_report } from targetDir + "/report/civ6_report/main.nf"

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

// First implementation, close to the original
workflow run_wf {
  take:
  input_ch

  main:
  output_ch = input_ch

    | preprocessInputs("config": config)

    // initialize the state
    | initState
    // Put the framerate aside for later:
    | toState{ id, data, state ->
      [
        combine_plots: [ framerate: data.framerate ],
        args: data
      ]
    }

    /**
      * The data-slot still contains input and framerate slots
        We have a choice now:
        - remove the framerate key and leave the input key
        - remove the framerate key and add the value of input as a value instead of a dict
        - leave the framerate key

        We chose the second option in this case.
    */
    | fromState{ id, data, state ->  state.args.input }

    // Run in parallel
    | ( parse_header & parse_map )
    | join

    // Format the result of the join as a tuple again
    /**
      * The output of parse_header is not just a path to the output
      * but also a path to the log file, so it's a dict:
      * [ output: ..., log: ... ]
      * We have to make sure to pass only the `output` part to the next step.
      * The log part will be dealt with later.
      */
    | map { id, header, state1, map, state2 -> 
      def new_data = [ "yaml" : header.output, "tsv": map ]
      [ id, new_data, state1 ] 
    }
    | plot_map
    | convert_plot
    | toSortedList{ a,b -> a[0] <=> b[0] }
    | map { tuples -> 
      new_data = [ input: tuples.collect{ it[1] }, output: "final.webm" ]
      [ "final", new_data, tuples[0][2] ] 
    }

    | fromState{ id, data, state -> mergeMap(data, state.combine_plots) }
    | combine_plots.run(
        directives: [ publishDir: "${params.publish_dir}" ]
    )

    /**
      * Logging output
      */
    parse_header.output
      | map{ id, data, state -> [ id, data.log, state ] }
      | toSortedList{ a,b -> a[0] <=> a[0] }
      | view
      | map{ tuples -> 
        new_data = [ input: tuples.collect{ it[1] }, output: "report.qmd" ]
        [ "report", new_data, tuples[0][2] ] }
      | aggregate
      | civ6_report


  emit:
  output_ch
}

