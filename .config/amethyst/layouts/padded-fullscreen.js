function layout() {
  return {
    name: "Padded Fullscreen",
    getFrameAssignments: (windows, screenFrame) => {
      // Amethyst が計算した画面領域をそのまま使い、設定済みの余白処理に追従する。
      return windows.reduce((frames, window) => {
        return {
          ...frames,
          [window.id]: {
            x: screenFrame.x,
            y: screenFrame.y,
            width: screenFrame.width,
            height: screenFrame.height
          }
        };
      }, {});
    }
  };
}
