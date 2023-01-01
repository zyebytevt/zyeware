// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.main;

import zyeware.common;
import zyeware.core.application;

/// Implement this function to return a valid ZyeWare application.
extern(C) Application createZyeWareApplication(string[] args);

version (unittest)
{
    // Keep free for the Silly test runner.
}
else
{
    int main(string[] args)
    {
        try
        {
            ZyeWareProperties props;

            props.application = createZyeWareApplication(args);

            ZyeWare.initialize(props);
            ZyeWare.start();
            ZyeWare.cleanup();
            return 0;
        }
        catch (Throwable t)
        {
            if (ZyeWare.crashHandler)
                ZyeWare.crashHandler.show(t);
            return 1;
        }
    }
}