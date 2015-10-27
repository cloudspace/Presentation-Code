/******************************************
# Detect if application is running on a VPN
******************************************/
public void isConnectedToVPN(final Handler.Callback c) throws IOException, RemoteException, InvocationTargetException, NoSuchMethodException, IllegalAccessException {
  WifiManager wifiManager = (WifiManager) getSystemService(WIFI_SERVICE);
  byte[] ipByte = BigInteger.valueOf(wifiManager.getConnectionInfo().getIpAddress()).toByteArray();
  ArrayUtils.reverse(ipByte);
  final String ip = InetAddress.getByAddress(ipByte).getHostAddress();
  Bundle b = new Bundle();
  String vpnIp = getIpFromVPN(this);
  boolean result = !vpnIp.isEmpty() && !ip.equals(vpnIp);
  b.putBoolean("result", result);
  Message m = new Message();
  m.setData(b);
  c.handleMessage(m);
}
