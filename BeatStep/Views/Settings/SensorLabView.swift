import Charts
import SwiftUI

struct SensorLabView: View {
    private var service: SensorLabService { .shared }
    private var cadence: CadenceService { .shared }

    var body: some View {
        List {
            // MARK: - Accelerometer

            Section("Accelerometer") {
                LabeledContent("X") {
                    Text(String(format: "%.4f g", service.accelerationX))
                }
                LabeledContent("Y") {
                    Text(String(format: "%.4f g", service.accelerationY))
                }
                LabeledContent("Z") {
                    Text(String(format: "%.4f g", service.accelerationZ))
                }
            }

            // MARK: - Cadence

            Section("Cadence") {
                LabeledContent("SPM") {
                    Text("\(cadence.currentSPM)")
                }
                LabeledContent("State") {
                    Text(String(describing: cadence.state))
                }
                LabeledContent("Steps") {
                    Text("\(service.stepCount)")
                }
            }

            // MARK: - Waveform

            Section("Waveform") {
                AccelerometerChartView(samples: service.samples)
                    .frame(height: 200)
            }

            // MARK: - Detection Interval

            Section("Detection Interval") {
                Slider(
                    value: Binding(
                        get: { service.detectionInterval },
                        set: { service.updateInterval($0) }
                    ),
                    in: 0.5 ... 5.0,
                    step: 0.5
                )

                Text(String(format: "%.1f s", service.detectionInterval))
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .navigationTitle("Sensor Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            SensorLabService.shared.startAccelerometer()
        }
        .onDisappear {
            SensorLabService.shared.stopAccelerometer()
        }
    }
}

// MARK: - Accelerometer Chart

private struct AccelerometerChartView: View {
    let samples: [AccelerometerSample]

    var body: some View {
        Chart(samples) { sample in
            LineMark(
                x: .value("Time", sample.timestamp),
                y: .value("Magnitude", sample.magnitude)
            )
            .foregroundStyle(Color.accent)
        }
        .chartYScale(domain: 0 ... 3)
        .drawingGroup()
    }
}
