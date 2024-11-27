/*
 * Miscellaneous helper functions.
 */

import java.text.*

/**
 * Give a number for the Java heap size based on the task memory, allowing for
 * some overhead for the JVM itself from the total allowed. The current overhead
 * is 128 MB.
 */
def javaMemMB(task)
{
    def overhead = 128
    def minimumHeap = 16

    def javaMem = task.memory.toMega() - overhead

    if (javaMem < minimumHeap)
    {
        throw new Exception("No memory after taking JVM overhead. Need at least ${overhead + minimumHeap} MB allocated.")
    }
    return javaMem
}

/**
 * Provide OpenJDK JVM memory configuration based on the memory given to the task.
 * Allocates a maximum Java meta space size, which is 128MB by default but can be
 * changed by defining the parameter "java_metaspace_size", down to a minimum of
 * 64MB (no maximum). Likewise the "java_overhead_size" parameter can give a size
 * for other memory overheads, down to a minimum of 32MB.
 * What's left of the task's memory after allocating the meta
 * space size plus the miscellaneous overhead is allocated for the JVM's heap.
 *
 * Returns an object with numerous fields (all numbers are megabytes):
 * "heap" - The heap size.
 * "metaSpace" - The meta space size.
 * "misc" - The additional overhead taken for everything else.
 * "all" - The task's allocated memory. Same as task.memory.toMega()
 * "jvmOpts" - The string to include in the Java command line for the program
 * to set the memory values as calculated. This string must not be quoted in
 * the shell script.
 */
def javaMemoryOptions(task)
{
    final def minimumHeap = 16 // The absolute minimum heap size.
    final def minimumMeta = 64 // The smallest allowed meta space size.
    final def minimumOverhead = 32 // The smallest allowed margin for other overheads.

    final def taskAllocation = task.memory.toMega()

    // Miscellaneous overhead for JNI, ByteBuffers etc.
    def overhead = params.getOrDefault('java_overhead_size', 64) * task.attempt
    if (overhead < minimumOverhead)
    {
        log.warn "java_overhead_size is set to ${overhead}, which is too small. Setting to the minimum of ${minimumOverhead}MB."
        overhead = minimumOverhead
    }

    // Meta space allocation.
    def metaSpace = params.getOrDefault('java_metaspace_size', 128) * task.attempt
    if (metaSpace < minimumMeta)
    {
        log.warn "java_metaspace_size is set to ${metaSpace}, which is too small. Setting to the minimum of ${minimumMeta}MB."
        metaSpace = minimumMeta
    }

    def heap = taskAllocation - overhead - metaSpace

    if (heap < minimumHeap)
    {
        log.error "Task ${task.name} attempt ${task.attempt}: allocated ${taskAllocation}MB; JVM overhead ${overhead}MB; Java Meta Space ${metaSpace}MB"
        throw new Exception("No memory left after taking JVM overheads. Need at least ${overhead + metaSpace + minimumHeap} MB allocated.")
    }

    def info = new Expando()
    info.heap = heap
    info.metaSpace = metaSpace
    info.misc = overhead
    info.all = taskAllocation
    info.jvmOpts = "-XX:MaxMetaspaceSize=${metaSpace}m -Xms${heap}m -Xmx${heap}m"

    return info
}

/**
 * Get the size of a collection of things. It might be that the thing
 * passed in isn't a collection or map, in which case the size is 1.
 * If null is passed in, return 0.
 *
 * See https://github.com/nextflow-io/nextflow/issues/2425
 *
 * See makeCollection below for Nextflow's own alternatives.
 */
def sizeOf(thing)
{
    if (thing instanceof Collection || thing instanceof Map)
    {
        return thing.size()
    }

    if (thing == null)
    {
        return 0
    }

    return 1
}

/**
 * Make sure a thing is a collection when required.
 * It might be that the thing passed in isn't a collection, in which
 * case make it a list containing the single thing.
 * If the thing is null, return null.
 *
 * See https://github.com/nextflow-io/nextflow/issues/2425
 *
 * This is resolved in Nextflow >= 23.9 with the "arity" attibute on
 * file and path. If arity is set to '1..*' a glob will return a
 * collection even if only one file is found to match the pattern.
 * Conversely, if arity is set to '1' a single file or path is returned
 * (i.e. not in a collection). Presumably an error is thrown if more
 * than one file matches.
 *
 * The "files" function can be used instead of "file" to create files
 * that will always be in a list, even if there is only one match.
 */
def makeCollection(thingOrList)
{
    if (thingOrList instanceof Collection)
    {
        return thingOrList
    }

    if (thingOrList != null)
    {
        return Collections.singletonList(thingOrList)
    }

    return null
}

/**
 * Make a name safe to be used as a file name. Everything that's not
 * alphanumeric, dot, underscore or hyphen is converted to an underscore.
 * Spaces are just removed.
 *
 * Note that commons-lang3 must be made available to use this function.
 * This is done by creating a "lib" directory in your pipeline and either
 * putting the commons-lang3 JAR file into that directory or (better)
 * putting a Groovy script in there that can still use @Grab to fetch
 * the file. This change came in with 24.10.
 *
 * See https://github.com/nextflow-io/nextflow/issues/5234
 */
def safeName(name)
{
    def nameStr = name.toString()
    def safe = new StringBuilder(nameStr.length())
    def iter = new StringCharacterIterator(nameStr)

    for (def c = iter.first(); c != CharacterIterator.DONE; c = iter.next())
    {
        switch (c)
        {
            case { org.apache.commons.lang3.CharUtils.isAsciiAlphanumeric(it) }:
            case '_':
            case '-':
            case '.':
                safe << c
                break

            case ' ':
            case '\t':
                // Add nothing.
                break

            default:
                safe << '_'
                break
        }
    }

    return safe.toString()
}
