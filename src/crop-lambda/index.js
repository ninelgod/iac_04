const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const Jimp = require("jimp");

const s3 = new S3Client({ region: "us-east-1" });
const BUCKET = process.env.S3_BUCKET;
const DEST = process.env.PROCESSED_PREFIX || "processed/";

function streamToBuffer(stream) {
  const chunks = [];
  return new Promise((resolve, reject) => {
    stream.on("data", (chunk) => chunks.push(chunk));
    stream.on("end", () => resolve(Buffer.concat(chunks)));
    stream.on("error", reject);
  });
}

exports.handler = async (event) => {
  const results = [];
  
  for (const sqsRecord of event.Records) {
    try {
      const s3Event = JSON.parse(sqsRecord.body);
      
      for (const s3Record of s3Event.Records) {
        const bucket = s3Record.s3.bucket.name;
        const key = decodeURIComponent(s3Record.s3.object.key.replace(/\+/g, " "));

        const response = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
        const imageBuffer = await streamToBuffer(response.Body);

        const image = await Jimp.read(imageBuffer);
        image.cover(40, 40);

        const mask = new Jimp(40, 40, 0x00000000);
        mask.circle({ radius: 20, x: 20, y: 20 });
        image.mask(mask, 0, 0);

        const result = await image.getBufferAsync(Jimp.MIME_PNG);

        const fileName = key.split("/").pop().replace(/\.[^.]+$/, "") + "_circular.png";
        const outputKey = DEST + fileName;

        await s3.send(new PutObjectCommand({
          Bucket: BUCKET,
          Key: outputKey,
          Body: result,
          ContentType: "image/png",
        }));

        results.push({ status: "ok", output: outputKey });
      }
    } catch (err) {
      console.error("Error processing SQS message", err);
      results.push({ status: "error", error: err.message });
    }
  }
  
  return results;
};