//
//  ScriptPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/31.
//

import SwiftUI
import Observation
import Combine

import CoreML

@Observable
final class ScriptPresenter {
    
    var code: String = """
async function main() {
  try {
    const vision = await art.Vision("anime2sketch");
    const inputImage = art.Image("image_2023-06-24_161601");
    inspect(inputImage);

    const sketchImage = await vision.perform(inputImage);
    inspect(sketchImage);

    const scribbleInputImage = art.Filter("CIColorInvert", {"inputImage": sketchImage}).render();
    inspect(scribbleInputImage);

    const diffusion = await art.Diffusion(
      "dreamshaper-v5 _original_512x512_for-controlnet",
      {
        computeUnits: "cpu&gpu",
        controlNets: ["Scribble-5x5"]
      }
    );

    const outputImage = await diffusion.perform(
      {
        prompt: "realistic, masterpiece, boy highest quality, full body, looking at viewers, highres, indoors, detailed face and eyes, wolf ears, brown hair, short hair, silver eyes, necklace, sneakers, parka jacket, solo focus",
        nagativePrompt: "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name",
        stepCount: 10,
        guidanceScale: 11,
        controlNetInputs: [{name: "Scribble-5x5", image: scribbleInputImage}]
      },
      (progress) => { inspect(progress.image); }
    );
    inspect("Done");
    inspect(outputImage);
  } catch (error) {
    print(error);
  }
}

//async function run() {
//  const vision = await art.Vision("anime2sketch");
//  const inputImage = art.Image("image_2023-05-11_090933");
//  inspect(inputImage);
//  const outputImage = await vision.perform(inputImage);
//  inspect(outputImage);
//}
//run()

//const matrix = art.Matrix().rotated(Math.PI / 4);
//const inputImage = art.Image("image_2023-05-11_090933");
//const final = art.Filter("CIAffineTransform", {inputImage: inputImage, inputTransform: matrix});
//const resultImage = final.render();
//inspect(resultImage);

//const gradient = genart.Filter("CILinearGradient", {
//  "inputPoint0": genart.Vector(0, 100),
//  "inputPoint1": genart.Vector(300, 200),
//  "inputColor0": genart.Color(1, 0, 0),
//  "inputColor1": genart.Color(0, 1, 0)
//});
//inspect(gradient.render());

//const final = genart.Filter("CIColorInvert", {"inputImage": gradient.outputImage});
//const inputImage = genart.Image("image_2023-05-11_090933");
//inspect(inputImage);
//const final = genart.Filter("CIGaussianBlur", {"inputImage": inputImage});
//const resultImage = final.render();
//inspect("Result:");
//inspect(resultImage);

"""
    var error: String = "No error"
    
    enum Log {
        case string(String)
        case image(CGImage)
    }
    private(set) var logs: [Log] = []

    @ObservationIgnored
    private var cancellable = Set<AnyCancellable>()

    init() {
        
    }
    
    func prepare() async {
    }
    
    func run() async {
        do {
            let context = ScriptContext()
            context.$inspectObject
                .sink { message in
                    if let message {
                        self.logs.append(message.toLog())
                    }
                }
                .store(in: &cancellable)
            
            try await context.run(code: code)
        } catch let exception as ScriptContext.Exception {
            error = "\(exception.line): \(exception.message)"
        } catch {
            dump(error)
        }
    }
}

private extension ScriptContext.InspectObject {
    func toLog() -> ScriptPresenter.Log {
        switch self {
        case .string(let string):
            return .string(string)
        case .number(let number):
            return .string(String(format: "%g", number))
        case .image(let image):
            return .image(image.cgImage)
        }
    }
}
