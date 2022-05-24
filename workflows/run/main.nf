nextflow.enable.dsl=2

targetDir = params.rootDir + "/target/nextflow"

include { plot_map } from targetDir + '/civ6_save_renderer/plot_map/main.nf'
include { combine_plots } from targetDir + '/civ6_save_renderer/combine_plots/main.nf'
include { convert_plot } from targetDir + '/civ6_save_renderer/convert_plot/main.nf'
include { parse_header } from targetDir + '/civ6_save_renderer/parse_header/main.nf'
include { parse_map } from targetDir + '/civ6_save_renderer/parse_map/main.nf'
include { aggregate } from targetDir + '/utils/aggregate/main.nf'

workflow {

    if (params.debug == true)
        println(params)

    if (!params.containsKey("input") || !params.input || params.input == "") {
        exit 1, "ERROR: Please provide a --input parameter pointing to .Civ6Save file(s)"
    }
    if (!params.containsKey("publishDir") || !params.publishDir || params.publishDir == "") {
        exit 1, "ERROR: Please provide a --publishDir parameter pointing to the directory to store output"
    }

    Channel.fromPath(params.input, checkIfExists: false)
        | map{ it -> [ it.baseName , [ input: it ] ] }
        | ( parse_header & parse_map )
        | join
        | map { id, header, map ->
                [ id, [ "yaml" : header.output, "tsv": map ] ] }    // pick out the .output part
        | plot_map
        | convert_plot
        | map{ it -> [ it[0], it[1].output ] }                      // idem
        | toSortedList{ a,b -> a[0] <=> b[0] }
        | map { tuples -> [ "final", [ input: tuples.collect{ it[1] }, output: "final.webm" ] ] }
        | combine_plots.run(
            auto: [ publish: true ]
        )

    // Report generation

    parse_header.out
        | toSortedList{ a,b -> a[0] <=> b[0] }
        | map { [ "", it.collect{ it[1].log } ] }
        | aggregate.run(                                          // no separate include required !
            key: 'aggregate1',
            mapData: { it -> [ input: it, docs: "parse_header_docs" ] },
        )

    convert_plot.out
        | toSortedList{ a,b -> a[0] <=> b[0] }
        | map { [ "", it.collect{ it[1].log } ] }
        | aggregate.run (                                          // no separate include required !
            key: 'aggregate2',
            mapData: { it -> [ input: it, docs: "convert_plot_docs" ] },
        )

    aggregate1.out
        | mix(aggregate2.out)
        | toSortedList { a,b -> a[1] <=> b[1] }
        | map { [ "", it.collect{ it[1] } ] }
        | aggregate.run (                                          // no separate include required !
            key: 'aggregate3',
            mapData: { it -> [ input: it, docs: "docs" ] },
            auto: [ publish: true ]
        )

    /*     | civ6_report */

}
