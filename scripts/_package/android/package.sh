cd android-project
mkdir -p ../artifacts
cp app/build/outputs/apk/release/*.apk ../artifacts/
cd ../artifacts && zip -r framebolt-android.zip ./*
mv framebolt-android.zip ../
cd ..
