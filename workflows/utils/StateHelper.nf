import static groovy.json.JsonOutput.prettyPrint
import groovy.json.JsonGenerator
import java.nio.file.Path
import java.time.OffsetDateTime
import nextflow.util.Duration

/**
* Create a pretty string format of a given object using JSON.
*
* @param object The given object (typically a map) that is to be represented as a
*     JSON-like pretty string.
* @return A JSON string.
*
* Based on: https://github.com/Midnighter/nextflow-utility-services
*/
def prettyFormat(Object object) {

  /**
  * Define a JSON generator with appropriate converters for problematic types.
  */
  def JsonGenerator generator = new JsonGenerator.Options()
      .dateFormat("yyyy-MM-dd'T'HH:mm:ssXXX")
      .addConverter(OffsetDateTime) { OffsetDateTime offset -> offset.toString() }
      .addConverter(Duration) { Duration duration -> duration.toString() }
      .addConverter(Path) { Path filename -> filename.toString() }
      .build()

  return prettyPrint(generator.toJson(object))
}


workflow splitState {
  take:
  input_

  main:
  output_ = input_
    | map{ tup -> 
      if (tup.size() < 2) {
        throw new RuntimeException("We need at least an ID and a data entry")
      }
      if (tup.size() > 3) {
        throw new RuntimeException("At most a triplet is required here")
      }
      if (tup.size == 2) {
        // No state is present, initialize and empty one
        [ tup[0], [:] ]
      }
      else {
        [ tup[0], tup[2] ]
      } 
    }

  emit:
  output = input_ | map{ it.subList(0,2) }
  state = output_
}

// TVE: superfluous
workflow initState {
  take:
  input_

  main:
  output_ = input_
    | map{ tup -> 
      if (tup.size() != 2) {
        println(tup)
        throw new RuntimeException("State already present!")
      }
      [ tup[0], tup[1], [:] ]
    }

  emit:
  output_
}

workflow initData {
  take:
  input_

  main:
  output_ = input_
    | map{ tup -> 
      [ tup[0], [:], tup[2] ]       // TODO: replace by call to fromArgsState
    }

  emit:
  output_
}

// TVE: may be confusing to allow 3 variants
def toState(Closure clos) {
  def numArgs = clos.maximumNumberOfParameters
  assert(numArgs == 1 | numArgs == 2 | numArgs == 3)
  
  workflow setterWf {
    take:
    input_

    main:
    output_ = input_
      | map{ tup -> 
          if (tup.size() != 3) {
            throw new RuntimeException("Should have 3 elements here!")
          }
          if (numArgs == 1) {
            [ tup[0], tup[1], clos(tup[1]) ]
          }
          else if (numArgs == 2) {
            [ tup[0], tup[1], clos(tup[1], tup[2]) ]
          } else {
            [ tup[0], tup[1], clos(tup[0], tup[1], tup[2]) ]
          }
        }

    emit:
    output_
  }

  return setterWf
}

// TVE: may be confusing to allow 3 variants
def fromState(Closure clos) {
  def numArgs = clos.maximumNumberOfParameters
  assert(numArgs == 1 | numArgs == 2 | numArgs == 3)
  
  workflow getterWf {
    take:
    input_

    main:
    output_ = input_
      | map{ tup -> 
          if (tup.size() != 3) {
            throw new RuntimeException("Should have 3 elements here!")
          }
          if (numArgs == 1) {
            [ tup[0], clos(tup[2]), tup[2] ]
          }
          else if (numArgs == 2) {
            [ tup[0], clos(tup[1], tup[2]), tup[2] ]
          } else {
            [ tup[0], clos(tup[0], tup[1], tup[2]), tup[2] ]
          }
        }

    emit:
    output_
  }

  return getterWf
}

// TVE: Should be rewritten to take exactly 3 elements, not more.
def addWorkflowArguments(Map args) {
  wfKey = args.key != null ? args.key : "addWorkflowArguments"
  args.keySet().removeAll(["key"])

  
  /*
  data = [a:1, b:2, c:3]
  // args = [foo: ["a", "b"], bar: ["b"]]
  args = [foo: [a: 'a', out: "b"], bar: [in: "b"]]
  */
  
  workflow addWorkflowArgumentsInstance {
    take:
    input_

    main:
    output_ = input_
      | map{ tup -> 
        assert tup.size() : "Event should have length 2 or greater. Expected format: [id, data]."
        def id = tup[0]
        def data = tup[1]
        def passthrough = tup.drop(2)

        // determine new data
        def toRemove = args.collectMany{ _, dataKeys -> 
          // dataKeys is a map but could also be a list
          dataKeys instanceof List ? dataKeys : dataKeys.values()
        }.unique()
        def newData = data.findAll{!toRemove.contains(it.key)}

        // determine splitargs
        def splitArgs = args.
          collectEntries{procKey, dataKeys -> 
          // dataKeys is a map but could also be a list
          newSplitData = dataKeys
            .collectEntries{ val ->
              newKey = val instanceof String ? val : val.key
              origKey = val instanceof String ? val : val.value
              [ newKey, data[origKey] ]
            }
            .findAll{it.value}
          [procKey, newSplitData]
        }

        // return output
        [ id, newData, passthrough + splitArgs ]
      }

    emit:
    output_
  }

  return addWorkflowArgumentsInstance.cloneWithName(wfKey)
}

/* usage:
| setWorkflowArguments(
  pca: [ "input": "input", "obsm_output": "obsm_pca" ]
  harmonypy: [ "obs_covariates": "obs_covariates", "obsm_input": "obsm_pca" ],
  find_neighbors: [ "obsm_input": "obsm_pca" ],
  umap: [ "output": "output" ]
)
*/

// TVE: Should be rewritten to take exactly 3 elements, not more.
def setWorkflowArguments(Map args) {
  wfKey = args.key != null ? args.key : "setWorkflowArguments"
  args.keySet().removeAll(["key"])

  
  /*
  data = [a:1, b:2, c:3]
  // args = [foo: ["a", "b"], bar: ["b"]]
  args = [foo: [a: 'a', out: "b"], bar: [in: "b"]]
  */
  
  workflow setWorkflowArgumentsInstance {
    take:
    input_

    main:
    output_ = input_
      | map{ tup -> 
        assert tup.size() : "Event should have length 2 or greater. Expected format: [id, data]."
        def id = tup[0]
        def data = tup[1]
        def passthrough = tup.drop(2)

        // determine new data
        def toRemove = args.collectMany{ _, dataKeys -> 
          // dataKeys is a map but could also be a list
          dataKeys instanceof List ? dataKeys : dataKeys.values()
        }.unique()
        def newData = data.findAll{!toRemove.contains(it.key)}

        // determine splitargs
        def splitArgs = args.
          collectEntries{procKey, dataKeys -> 
          // dataKeys is a map but could also be a list
          newSplitData = dataKeys
            .collectEntries{ val ->
              newKey = val instanceof String ? val : val.key
              origKey = val instanceof String ? val : val.value
              [ newKey, data[origKey] ]
            }
            .findAll{it.value}
          [procKey, newSplitData]
        }

        // return output
        [ id, newData, splitArgs] + passthrough
      }

    emit:
    output_
  }

  return setWorkflowArgumentsInstance.cloneWithName(wfKey)
}

/* usage:
| getWorkflowArguments("harmonypy")
*/

// TVE: Should be rewritten to take exactly 3 elements, not more.
def getWorkflowArguments(Map args) {
  def inputKey = args.inputKey != null ? args.inputKey : "input"
  def wfKey = "getWorkflowArguments_" + args.key
  
  workflow getWorkflowArgumentsInstance {
    take:
    input_

    main:
    output_ = input_
      | map{ tup ->
        assert tup.size() : "Event should have length 3 or greater. Expected format: [id, data, splitArgs]."

        def id = tup[0]
        def data = tup[1]
        def splitArgs = tup[2].clone()
        
        def passthrough = tup.drop(3)

        // try to infer arg name
        if (data !instanceof Map) {
          data = [[ inputKey, data ]].collectEntries()
        }
        assert splitArgs instanceof Map: "Third element of event (id: $id) should be a map"
        assert splitArgs.containsKey(args.key): "Third element of event (id: $id) should have a key ${args.key}"
        
        def newData = data + splitArgs.remove(args.key)

        [ id, newData, splitArgs] + passthrough
      }

    emit:
    output_
  }

  return getWorkflowArgumentsInstance.cloneWithName(wfKey)

}

// TVE: Can be omitted
def strictMap(Closure clos) {
  def numArgs = clos.class.methods.find{it.name == "call"}.parameterCount
  
  workflow strictMapWf {
    take:
    input_

    main:
    output_ = input_
      | map{ tup -> 
        if (tup.size() != numArgs) {
          throw new RuntimeException("Closure does not have the same number of arguments as channel tuple.\nNumber of closure arguments: $numArgs\nChannel tuple: $tup")
        }
        clos(tup)
      }

    emit:
    output_
  }

  return strictMapWf
}

// TVE: Can be omitted
def passthroughMap(Closure clos) {
  def numArgs = clos.class.methods.find{it.name == "call"}.parameterCount
  
  workflow passthroughMapWf {
    take:
    input_

    main:
    output_ = input_
      | map{ tup -> 
        def out = clos(tup.take(numArgs))
        out + tup.drop(numArgs)
      }

    emit:
    output_
  }

  return passthroughMapWf
}

// TVE: Can be omitted
def passthroughFlatMap(Closure clos) {
  def numArgs = clos.class.methods.find{it.name == "call"}.parameterCount
  
  workflow passthroughFlatMapWf {
    take:
    input_

    main:
    output_ = input_
      | flatMap{ tup -> 
        def out = clos(tup.take(numArgs))
        def pt = tup.drop(numArgs)
        for (o in out) {
          o.addAll(pt)
        }
        out
      }

    emit:
    output_
  }

  return passthroughFlatMapWf
}

// TVE: Can be omitted
def passthroughFilter(Closure clos) {
  def numArgs = clos.class.methods.find{it.name == "call"}.parameterCount
  
  workflow passthroughFilterWf {
    take:
    input_

    main:
    output_ = input_
      | filter{ tup -> 
        clos(tup.take(numArgs))
      }

    emit:
    output_
  }

  return passthroughFilterWf
}
