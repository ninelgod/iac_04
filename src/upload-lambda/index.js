const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const crypto = require("crypto");
const busboy = require("busboy");

const s3 = new S3Client({ region: "us-east-1" });
const BUCKET = process.env.S3_BUCKET;
const PREFIX = process.env.UPLOAD_PREFIX || "uploads/";

exports.handler = async (event) => {
  try {
    console.log("Evento recibido:", JSON.stringify({
      isBase64Encoded: event.isBase64Encoded,
      headers: event.headers,
      bodyLength: event.body ? event.body.length : 0,
    }));

    const contentType = event.headers["content-type"];
    if (!contentType || !contentType.includes("multipart/form-data")) {
      console.error("Falta content-type multipart/form-data");
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: "Only multipart/form-data" })
      };
    }

    const bodyBuffer = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body, "utf8");

    const bb = busboy({ headers: { "content-type": contentType } });
    const fields = {};
    let fileBuffer;
    let fileName;
    let mime;

    bb.on("file", (name, file, info) => {
      mime = info.mimeType;
      fileName = info.filename;
      const chunks = [];
      file.on("data", (chunk) => chunks.push(chunk));
      file.on("end", () => {
        fileBuffer = Buffer.concat(chunks);
      });
    });

    bb.on("field", (name, val) => { fields[name] = val; });

    await new Promise((resolve, reject) => {
      bb.on("close", resolve);
      bb.on("error", reject);
      bb.end(bodyBuffer);
    });

    if (!fileBuffer) {
      console.error("No se encontró archivo en el formulario");
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: "No file uploaded" })
      };
    }

    if (fileBuffer.length > 10 * 1024 * 1024) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: "File too large. Max 10 MB" })
      };
    }

    const allowed = ["image/jpeg", "image/png", "image/gif", "image/webp"];
    if (!allowed.includes(mime)) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: "Invalid format. Allowed: jpg, png, gif, webp" })
      };
    }

    const ext = fileName.split(".").pop();
    const key = PREFIX + crypto.randomUUID() + "." + ext;

    await s3.send(new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: fileBuffer,
      ContentType: mime,
    }));

    console.log("Archivo subido con éxito:", key);
    return {
      statusCode: 201,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: "Uploaded", key })
    };
  } catch (err) {
    console.error("Error en upload-lambda:", err);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: "Internal Server Error", error: err.message })
    };
  }
};