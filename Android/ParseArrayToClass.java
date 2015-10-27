/************************************************************
# Parse a json array into an array of the supplied class type
************************************************************/
public BaseApiModel[] parseObjectToArray(JSONArray jsonArray, Class<?> toClass) {
	BaseApiModel[] res = new BaseApiModel[jsonArray.length()];
	for (int i = 0; i < jsonArray.length(); i++) {
		try {
			BaseApiModel item = (BaseApiModel) toClass
					.getDeclaredConstructor(JSONObject.class).newInstance(
							jsonArray.getJSONObject(i));

			res[i] = item;
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	return res;
}