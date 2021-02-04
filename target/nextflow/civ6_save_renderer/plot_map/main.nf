nextflow.preview.dsl=2
import java.nio.file.Paths

def renderCLI(command, arguments) {

    def argumentsList = arguments.collect{ it ->
        (it.otype == "")
            ? "\'" + it.value + "\'"
            : (it.type == "boolean_true")
                ? it.otype + it.name
                : (it.value == "")
                    ? ""
                    : it.otype + it.name + " \'" + ((it.value in List && it.multiple) ? it.value.join(it.multiple_sep): it.value) + "\'"
    }

    def command_line = command + argumentsList

    return command_line.join(" ")
}

def effectiveContainer(processParams) {
    def _registry = params.containsKey("containerRegistry") ? params.containerRegistry + "/" : ""
    def _name = processParams.container
    def _tag = params.containsKey("containerTag") ? "${params.containerTag}" : "${processParams.containerTag}"

    return "${_registry}${_name}:${_tag}"
}

// files is either String, List[String] or HashMap[String,String]
def outFromIn(files) {
    if (files in List || files in HashMap) {
        // We're in join mode, files is List[String]
        return "plot_map" + "." + "pdf"
    } else {
        // files filename is just a String
        def splitString = files.split(/\./)
        def prefix = splitString.head()
        def extension = splitString.last()
        return prefix + "." + "plot_map" + "." + "pdf"
    }
}

// In: Hashmap key -> DataObjects
// Out: Arrays of DataObjects
def overrideInput(params, str) {

    // `str` in fact can be one of:
    // - `String`,
    // - `List[String]`,
    // - `Map[String, String | List[String]]`
    // Please refer to the docs for more info
    def overrideArgs = params.arguments.collect{ it ->
      (it.value.direction == "Input" && it.value.type == "file")
        ? (str in List || str in HashMap)
            ? (str in List)
                ? it.value + [ "value" : str.join(it.value.multiple_sep)]
                : (str[it.value.name] != null)
                    ? (str[it.value.name] in List)
                        ? it.value + [ "value" : str[it.value.name].join(it.value.multiple_sep)]
                        : it.value + [ "value" : str[it.value.name]]
                    : it.value
            : it.value + [ "value" : str ]
        : it.value
    }

    def newParams = params + [ "arguments" : overrideArgs ]

    return newParams
}

def overrideOutput(params, str) {

    def update = [ "value" : str ]

    def overrideArgs = params.arguments.collect{it ->
      (it.direction == "Output" && it.type == "file")
        ? it + update
        : it
    }

    def newParams = params + [ "arguments" : overrideArgs ]

    return newParams
}


process plot_map_process {
  
  tag "${id}"
  echo { (params.debug == true) ? true : false }
  cache 'deep'
  stageInMode "symlink"
  container "${container}"
  
  input:
    tuple val(id), path(input), val(output), val(container), val(cli)
  output:
    tuple val("${id}"), path("${output}")
  script:
    if (params.test)
        """
        # Some useful stuff
        export NUMBA_CACHE_DIR=/tmp/numba-cache
        # Running the pre-hook when necessary
        echo Nothing before
        # Adding NXF's `$moduleDir` to the path in order to resolve our own wrappers
        export PATH="./:${moduleDir}:\$PATH"
        ./${params.plot_map.tests.testScript} | tee $output
        """
    else
        """
        # Some useful stuff
        export NUMBA_CACHE_DIR=/tmp/numba-cache
        # Running the pre-hook when necessary
        echo Nothing before
        # Adding NXF's `$moduleDir` to the path in order to resolve our own wrappers
        export PATH="${moduleDir}:\$PATH"
        $cli
        """
}

workflow plot_map {

    take:
    id_input_params_

    main:

    def key = "plot_map"

    def id_input_output_function_cli_ =
        id_input_params_.map{ id, input, _params ->
            // TODO: make sure input is List[Path], HashMap[String,Path] or Path, otherwise convert
            // NXF knows how to deal with an List[Path], not with HashMap !
            def checkedInput =
                (input in HashMap)
                    ? input.collect{ k, v -> v }.flatten()
                    : input
            // filename is either String, List[String] or HashMap[String, String]
            def filename =
                (input in List || input in HashMap)
                    ? (input in List)
                        ? input.collect{ it.name }
                        : input.collectEntries{ k, v -> [ k, (v in List) ? v.collect{it.name} : v.name ] }
                    : input.name
            def defaultParams = params[key] ? params[key] : [:]
            def overrideParams = _params[key] ? _params[key] : [:]
            def updtParams = defaultParams + overrideParams
            // now, switch to arrays instead of hashes...
            def outputFilename = (!params.test) ? outFromIn(filename) : updtParams.output
            def updtParams1 = overrideInput(updtParams, filename)
            def updtParams2 = overrideOutput(updtParams1, outputFilename)
            new Tuple5(
                id,
                checkedInput,
                outputFilename,
                effectiveContainer(updtParams2),
                renderCLI([updtParams2.command], updtParams2.arguments)
            )
        }
    result_ = plot_map_process(id_input_output_function_cli_) \
        | join(id_input_params_) \
        | map{ id, output, input, original_params ->
            new Tuple3(id, output, original_params)
        }

    emit:
    result_

}

workflow {

   def id = params.id
   def ch_ = Channel.fromPath(params.input).map{ s -> new Tuple3(id, s, params)}

   plot_map(ch_)
}

workflow test {

   take:
   rootDir

   main:
   params.test = true
   params.plot_map.output = "plot_map.log"

   Channel.from(rootDir) \
        | filter { params.plot_map.tests.isDefined } \
        | map{ p -> new Tuple3(
                    "tests",
                    params.plot_map.tests.testResources.collect{ file( p + it ) },
                    params
                )} \
        | plot_map

    emit:
    plot_map.out
}