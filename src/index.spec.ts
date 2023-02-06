import { handler } from "./index";

describe("hello world", () => {
  it("should return hello world", async () => {
    const result = await handler(
      {
        requestContext: {
          http: {
            method: "GET",
            path: "/hello/world",
          },
        },
        headers: {
          "content-type": "application/json",
        },
      } as any,
      {} as any,
      () => {}
    );

    expect((result as any).statusCode).toEqual(200);
    expect((result as any).body).toEqual(
      JSON.stringify({ message: "Hello world" })
    );
  });
});
