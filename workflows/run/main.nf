nextflow.enable.dsl=2

workflowDir = params.rootDir + "/workflows"
targetDir = params.rootDir + "/target/nextflow"

include  { plot_map }      from  targetDir + '/civ6_save_renderer/plot_map/main.nf'       params(params)
include  { combine_plots } from  targetDir + '/civ6_save_renderer/combine_plots/main.nf'  params(params)
include  { convert_plot }  from  targetDir + '/civ6_save_renderer/convert_plot/main.nf'   params(params)
include  { filterOutput as convert_plot_output }  from  targetDir + '/civ6_save_renderer/convert_plot/main.nf'   params(params)
include  { filterLog as convert_plot_log }  from  targetDir + '/civ6_save_renderer/convert_plot/main.nf'   params(params)
include  { parse_header }  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { filterOutput as parse_header_output }  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { filterLog as parse_header_log}  from  targetDir + '/civ6_save_renderer/parse_header/main.nf'   params(params)
include  { parse_map }     from  targetDir + '/civ6_save_renderer/parse_map/main.nf'      params(params)
include  { concat } from targetDir + '/markdown/concat/main.nf' params(params)
include  { aggregate as aggregate1 } from targetDir + '/utils/aggregate/main.nf' params(params)
include  { aggregate as aggregate2 } from targetDir + '/utils/aggregate/main.nf' params(params)
include  { aggregate as aggregate3 } from targetDir + '/utils/aggregate/main.nf' params(params)
include  { overrideOptionValue } from workflowDir + "/utils.nf"
include  { civ6_report } from targetDir + '/report/civ6_report/main.nf' params(params)

workflow {

    if (params.debug == true)
        println(params)

    if (!params.containsKey("input") || !params.input || params.input == "") {
        exit 1, "ERROR: Please provide a --input parameter pointing to .Civ6Save file(s)"
    }
    if (!params.containsKey("publishDir") || !params.publishDir || params.publishDir == "") {
        exit 1, "ERROR: Please provide a --publishDir parameter pointing to the directory to store output"
    }

    input_ = Channel.fromPath(params.input, checkIfExists: false)
        | map{ it -> [ it.baseName , it, params ] }

    // Workflow

    input_
        | parse_header | parse_header_output
        | join( input_ | parse_map )
        | map{ id, data_parse_header, params1, data_parse_map, params2 ->
            [ id, [ "yaml" : data_parse_header, "tsv": data_parse_map ], params1 ] }
        | plot_map
        | convert_plot | convert_plot_output
        | toSortedList{ a,b -> a[0] <=> b[0] }
        | map{ tuples -> [ "final", tuples.collect{it[1]}, params ] }
        | combine_plots

    // Report generation

    parse_header.out
        | parse_header_log
        | toSortedList{ a,b -> a[1] <=> b[1] }
        | map { [ "", it.collect{it[1]}, params ] }
        | map { overrideOptionValue( it, "aggregate", "docs", "/parse_header" ) }
        | aggregate1

    convert_plot.out
        | convert_plot_log
        | toSortedList{ a,b -> a[1] <=> b[1] }
        | map { [ "", it.collect{it[1]}, params ] }
        | map { overrideOptionValue( it, "aggregate", "docs", "/convert_plot" ) }
        | aggregate2

    aggregate1.out
        | mix(aggregate2.out)
        | toSortedList { a,b -> a[1] <=> b[1] }
        | map { [ "", it.collect{it[1]}, params ] }
        | map { overrideOptionValue( it, "aggregate", "docs", "/" ) }
        | aggregate3

    aggregate3.out
        | map { overrideOptionValue( it, "civ6_report", "report", "_full" ) }
        | civ6_report

}
