WBXSLTProcessor
===============

### Using WBXSLTProcessor in your projects
* Add the `libxml2` and `libxslt` frameworks to your project.
* Find *Other Linker Flags* in the Build Settings. Add `-I${SDK_DIR}/usr/include/libxml2 -I${SDK_DIR}/usr/include/libxslt` to the value.
* Find *Other C Flags* in the Build Settings. Add `-lxml2` to the value.

* Copy the `WBXSLTProcessor .h` and `.m` to your project.

### Operation System version

WBXSLTProcessor works fine on 10.6 Snow Leopard, 10.7 Lion, and on 10.8 Mountain Lion, as libxml2 and libxslt are both present in these systems.


Good luck
Matt.
September 2012.
