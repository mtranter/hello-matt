import { httpApiHandler } from "@ezapi/aws-http-api-backend";
import { JsonParserMiddlerware } from "@ezapi/json-middleware";
import { Ok, RouteBuilder } from "@ezapi/router-core";

export const routes = RouteBuilder.withMiddleware(JsonParserMiddlerware())
  .route("GET", "/hello/{name}")
  .handle(async (r) => Ok({ message: `Hello ${r.pathParams.name}` }))
  .build();

export const handler = httpApiHandler(routes, "live");
