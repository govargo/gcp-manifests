const functions = require('@google-cloud/functions-framework');
const fetch = require('node-fetch');

const webhookURL = process.env.WEBHOOK_URL;

functions.http('sendNotificationForAlertmanagerToChat', async (req, res) => {
  console.log(req.body);

  if (!isValidRequest(req)) {
    return res.status(400).send('Invalid Alertmanager webhook JSON format');
  }

  res.status(200).send('Notification acknowledged');

  try {
    const cardMessage = JSON.stringify(createChatCard(req));
    const response = await fetch(webhookURL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: cardMessage,
    });

    if (!response.ok) {
      console.error(`Failed to send notification to chat: ${response.status} ${response.statusText}`);
    } else {
      console.log('Notification sent successfully');
    }
  } catch (error) {
    console.error(`Error sending notification: ${error}`);
  }
});

const isValidRequest = (req) => {
  const { version, alerts } = req.body;
  if (!version) {
    console.error("Missing 'version' in request body");
    return false;
  }
  if (!alerts) {
    console.error("Missing 'alerts' in request body");
    return false;
  }
  return true;
};

const createChatCard = (req) => {
  const { alerts, commonLabels, status } = req.body;
  const alert = alerts[0];

  const sections = [
    {
      header: "Alert notification",
      collapsible: false,
      uncollapsibleWidgetsCount: 1,
      widgets: [
        createDecoratedTextWidget("EMAIL", alert.annotations.summary),
        createDecoratedTextWidget("CONFIRMATION_NUMBER_ICON", commonLabels.severity),
        createDecoratedTextWidget("STAR", status),
        createDecoratedTextWidget("CLOCK", alert.startsAt),
        createDecoratedTextWidget("BOOKMARK", alert.labels.cluster),
        createDecoratedTextWidget("MAP_PIN", alert.labels.pod),
        createDecoratedTextWidget("DESCRIPTION", alert.annotations.description, true), // wrapText: true
      ],
    },
  ];

  return {
    cardsV2: [{
      cardId: 'alertmanager',
      card: {
        name: 'Alertmanager',
        header: {
          title: alert.labels.alertname,
          imageUrl: "https://avatars.githubusercontent.com/u/3380462?s=200&v=4",
          imageType: "CIRCLE",
        },
        sections,
      },
    }],
  };
};

const createDecoratedTextWidget = (icon, text, wrapText = false) => ({
  decoratedText: {
    startIcon: { knownIcon: icon },
    text,
    ...(wrapText && { wrapText }),
  },
});
