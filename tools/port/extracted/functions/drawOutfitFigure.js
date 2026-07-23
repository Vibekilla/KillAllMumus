function drawOutfitFigure(cx, cy, scale, t, poseOverride, outfitOverride){   // animated Bobina in the previewed outfit + selected pose + selected victory face
  drawPosedFigure(cx, cy, scale, t, (poseOverride!=null?poseOverride:outfitPose), (outfitOverride||outfitPreview), 1, VICTORY_FACES[victoryFace].expr);
}
