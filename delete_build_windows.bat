cd mupdf\platform\win32
msbuild mupdf.sln /t:Clean /p:Configuration=Debug;Platform=x64
msbuild mupdf.sln /t:Clean /p:Configuration=Release;Platform=x64
msbuild mupdf.sln /t:Clean /p:Configuration=Debug
msbuild mupdf.sln /t:Clean /p:Configuration=Release
cd ..\..\..

cd zlib
nmake -f win32\makefile.msc clean
cd ..

msbuild sioyek.vcxproj /t:Clean /p:Configuration=Debug;Platform=x64
msbuild sioyek.vcxproj /t:Clean /p:Configuration=Release;Platform=x64
msbuild sioyek.vcxproj /t:Clean /p:Configuration=Debug
msbuild sioyek.vcxproj /t:Clean /p:Configuration=Release

rmdir /S /Q release
rmdir /S /Q debug

del sioyek.vcxproj
del sioyek.vcxproj.filters
del sioyek_resource.rc
del sioyek-release-windows.zip
