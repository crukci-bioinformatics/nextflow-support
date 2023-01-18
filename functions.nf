/*
 * Miscellaneous helper functions.
 */

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
