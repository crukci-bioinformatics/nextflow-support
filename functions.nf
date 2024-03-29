/*
 * Miscellaneous helper functions.
 */

@Grab('org.apache.commons:commons-lang3:3.12.0')

import static org.apache.commons.lang3.CharUtils.isAsciiAlphanumeric

import java.text.*

/**
 * Give a number for the Java heap size based on the task memory, allowing for
 * some overhead for the JVM itself from the total allowed.
 */
def javaMemMB(task)
{
    def overhead = 64
    def minimum = 16

    def javaMem = task.memory.toMega() - overhead

    if (javaMem < minimum)
    {
        throw new Exception("No memory after taking JVM overhead. Need at least ${overhead + minimum} MB allocated.")
    }
    return javaMem
}

/**
 * Get the size of a collection of things. It might be that the thing
 * passed in isn't a collection or map, in which case the size is 1.
 * If null is passed in, return 0.
 *
 * See https://github.com/nextflow-io/nextflow/issues/2425
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
            case { isAsciiAlphanumeric(it) }:
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
