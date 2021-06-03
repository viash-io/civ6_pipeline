nextflow.enable.dsl=2

workflow {

    if (params.debug == true)
        println(params)

    if (!params.containsKey("input") || params.input == "") {
        exit 1, "ERROR: Please provide a --input parameter pointing to .Civ6Save file(s)"
    }

    def listToTriplet = { it -> [ "", it.collect{ a -> a[1] }, params ] }

    Channel.fromPath(params.input, checkIfExists: false) \
        | map{ it -> [ it.baseName , it, params ] } \
        | ( parse_header & parse_map ) \
        | join \
        | map{ id, parse_headerOut, params1, parse_mapOut, params2 ->
            [ id, [ "yaml" : parse_headerOut, "tsv": parse_mapOut ], params1 ] } \
        | plot_map \
        | convert_plot \
        | rename \
        | toSortedList{ a,b -> a[0] <=> b[0] }  \
        | map( listToTriplet ) \
        | combine_plots

}
