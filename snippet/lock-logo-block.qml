    // User logo above the password field, tinted with the active theme color
    Item {
      anchors.bottom: inputField.top
      anchors.bottomMargin: 24
      anchors.horizontalCenter: inputField.horizontalCenter
      width: logoImage.width
      height: logoImage.height

      Image {
        id: logoImage
        source: Qt.resolvedUrl("assets/logo-tint.png")
        sourceSize.width: 240
        fillMode: Image.PreserveAspectFit
        smooth: true
      }

      MultiEffect {
        anchors.fill: logoImage
        source: logoImage
        colorization: 1.0
        colorizationColor: Commons.Color.lock.text
      }
    }

