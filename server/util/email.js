import axios from "axios";
import nodemailer from "nodemailer";

const {
  SMTP_HOST,
  SMTP_PORT,
  SMTP_USER,
  SMTP_PASS,
  SMTP_FROM,
  RESEND_API_KEY,
  RESEND_FROM,
} = process.env;

const transportOptions = {
  host: SMTP_HOST,
  port: Number(SMTP_PORT) || 587,
  secure: Number(SMTP_PORT) === 465,
  auth: {
    user: SMTP_USER,
    pass: SMTP_PASS,
  },
};

const transporter = nodemailer.createTransport(transportOptions);

const assertSmtpConfig = () => {
  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
    throw new Error("SMTP configuration is missing");
  }
};

const resolveFromAddress = () => RESEND_FROM || SMTP_FROM || SMTP_USER;

const sendEmailWithResend = async ({ to, subject, text }) => {
  if (!RESEND_API_KEY) {
    throw new Error("RESEND_API_KEY is missing");
  }

  const from = resolveFromAddress();
  if (!from) {
    throw new Error("Email from address is missing");
  }

  await axios.post(
    "https://api.resend.com/emails",
    {
      from,
      to,
      subject,
      text,
    },
    {
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
    }
  );
};

const sendEmailWithSmtp = async ({ to, subject, text }) => {
  assertSmtpConfig();
  const from = resolveFromAddress();
  return transporter.sendMail({ from, to, subject, text });
};

const sendEmail = async ({ to, subject, text }) => {
  if (RESEND_API_KEY) {
    return sendEmailWithResend({ to, subject, text });
  }

  return sendEmailWithSmtp({ to, subject, text });
};

export const sendPasswordResetEmail = async ({ to, otp, userType }) => {
  const subject = "Reset your FacultyPedia password";
  const text = `Hi,

We received a request to reset your ${userType} account password.

Your one-time password (OTP) is: ${otp}

This OTP expires in 5 minutes. If you did not request this, you can ignore this email.

Thanks,
FacultyPedia Team`;

  return sendEmail({ to, subject, text });
};

export const sendVerificationEmail = async ({ to, otp }) => {
  const subject = "Verify your FacultyPedia email";
  const text = `Hi,

Use the OTP below to verify your FacultyPedia account email.

Your one-time password (OTP) is: ${otp}

This OTP expires in 5 minutes. If you did not request this, you can ignore this email.

Thanks,
FacultyPedia Team`;

  return sendEmail({ to, subject, text });
};

export const sendInvoiceEmail = async ({ to, payout, educator, pdfBuffer }) => {
  assertSmtpConfig();

  const from = SMTP_FROM || SMTP_USER;
  const subject = `Payout Invoice - ${
    payout?.payoutCheckId || payout?._id || ""
  }`;

  const text = `Hi ${educator?.fullName || "Educator"},

Your payout has been processed successfully.
Reference: ${payout?.payoutCheckId || ""}
Period: ${payout?.month}/${payout?.year}
Amount: Rs ${(Number(payout?.amount || 0) / 100).toFixed(2)}

The invoice is attached for your records.

Thanks,
FacultyPedia Team`;

  const attachments = pdfBuffer
    ? [
        {
          filename: `${payout?.payoutCheckId || "payout"}-invoice.pdf`,
          content: pdfBuffer,
        },
      ]
    : [];

  return transporter.sendMail({ from, to, subject, text, attachments });
};
