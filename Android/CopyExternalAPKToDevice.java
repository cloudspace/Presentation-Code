/*******************************************************************
# Copy and install a bundled external apk, in this case open_vpn.apk
*******************************************************************/
private void copyApkToExternal() throws IOException {
  InputStream in = getResources().openRawResource(R.raw.open_vpn);
  FileOutputStream out = new FileOutputStream(Environment.getExternalStorageDirectory() + "/open_vpn.apk");
  byte[] buff = new byte[1024];
  int read = 0;
  try {
    while ((read = in.read(buff)) > 0) {
      out.write(buff, 0, read);
    }
  } finally {
    in.close();
    out.close();

    Intent promptInstall = new Intent(Intent.ACTION_VIEW);
    promptInstall.setDataAndType(Uri.fromFile(new File(Environment.getExternalStorageDirectory() + "/open_vpn.apk")),
            "application/vnd.android.package-archive");

    startActivity(promptInstall);
  }
}
