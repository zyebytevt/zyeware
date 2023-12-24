module zyeware.utils.singleton;

// Thanks to David Simcha for this pattern!
mixin template Singleton(T)
{
    private this() {}

    // Cache instantiation flag in thread-local bool
    // Thread local
    private static bool instantiated_;

    // Thread global
    private __gshared T instance_;

    static T instance()
    {
        if (!instantiated_)
        {
            synchronized(T.classinfo)
            {
                if (!instance_)
                {
                    instance_ = new T();
                }

                instantiated_ = true;
            }
        }

        return instance_;
    }
}